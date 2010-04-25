#
# Ruby�ˤ�뼫��CMS (Pegasus��)
# �����ץ����
#

#��ʬ��̾��
ADMIN_SCRIPT = "index.rb";

load("../setting.rb");
require("../module/util.rb");
require("../module/lock_file.rb");
require("../module/page_counter.rb");
require("../module/page_reader.rb");
require("../module/page_request.rb");
require 'cgi.rb';
require "fileutils.rb";

$Title = nil;
$Mode = 0;
def main()
	init();
	setTitle();
	showHeader();
	showSideBar();
	showMiddle();
	showContent();
	showFooter();
	close();
end

def init()
	initRequest({"mode"=>"info"},{"color"=>DEFAULT_CSS},{},["color"]);
	InitPageIndex();
	checkCookie();
end

def close()
	$Title = nil;
	$Mode = nil;
	ClosePageIndex();
end

def checkCookie()
	color = $CookieHash["color"].untaint();
	if color != nil
		if !FileTest.exist?(SKIN_DIR+color+".css");
			$CookieHash["color"] = DEFAULT_CSS;
		end
	else
		$CookieHash["color"] = DEFAULT_CSS;
	end
end

def showSideBar()
	puts "<ul>"
	puts "<li><a href=\"../\">#{WEB_TITLE}</a></li>"
	puts "</ul>"
	puts "<h1>°���ѹ�</h1>"
	puts "<ul>"
	if $RequestHash.has_key?("color")
		query = getQuery("color","white");
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{query}\">��°��</a></li>"
		query = getQuery("color","black");
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{query}\">��°��</a></li>"
	else
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{$QueryString}&amp;color=white\">��°��</a></li>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{$QueryString}&amp;color=black\">��°��</a></li>"
	end
	puts "</ul>"
	puts "<h1>������˥塼</h1>"
	puts "<ul>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}\">�ڡ�������</a></li>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=new\">�����ڡ���</a></li>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">�ڡ�������ɽ��</a></li>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=file\">�ե�����</a></li>"
	puts "</ul>"
end
def showContent()
	case $Mode
		when 0#info
			showInfo();
		when 1#view
			showContentIndex();
		when 2#new
			showEdit(true);
		when 3#delete
			showDelete();
		when 4#edit
			showEdit(false);
		when 5#file
			showUpload();
	end
end

def setTitle()
	case $RequestHash["mode"]
		when "info"
			$Title = "�ڡ�������"
			$Mode = 0;
		when "view"
			$Title = "����ɽ��"
			$Mode = 1;
		when "new"
			$Title = "��������"
			$Mode = 2;
		when "delete"
			$Title = "���"
			$Mode = 3;
		when "edit"
			$Title = "�Խ�"
			$Mode = 4;
		when "file"
			$Title = "�ե�����"
			$Mode = 5;
	end
end

FILE_PREFIX = "file_";
def showUpload()
	del_array = [];
	$RequestHash.each_pair {|key, value|
		if key.index(FILE_PREFIX) == 0 && value == "file"
			del_array.push(key.slice(FILE_PREFIX.length..key.length));
		end
	}
catch(:out) do
	case $RequestHash["state"]
	when "ok"
		puts "�¹Ԥ��ޤ�������̤ϰʲ��ΤȤ���Ǥ���"
		puts "<ul>"
		del_array.each {|file|
			begin
				file = UPLOAD_DIR+file.dup.untaint();
				dir = File.expand_path(file);
				if dir.index(UPLOAD_DIR) != 0
					raise "Security Error #{dir}"
				end
				File.delete(file)
			rescue  => exc
				puts "<li>#{file}�����Ԥ��ޤ��������顼��#{exc}</li>"
			else
				puts "<li>#{file}���������ޤ�����</li>"
			end
		}
		puts "</ul>"
	when "delete"
		puts "�ʲ��Υե�����������ޤ���������Ǥ�����"
		puts "<ul>"
		ok_url = "#{ADMIN_SCRIPT}?"+ $QueryString.gsub("state=delete","state=ok");
		puts "<li><a href=\"#{ok_url}\">�Ϥ�</a></li>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=file\">���</a></li>"
		puts "</ul>"
		puts "<hr />"
		puts "<ul>"
		del_array.each {|file|
			puts "<li>#{file}</li>"
		}
		puts "</ul>"
		return;
	when "change_name"
		original = $RequestHash["original"];
		if original == nil || original == ""
			puts "���ꥸ�ʥ��̾���ϡ�������"
			throw :out
		end
		change = $RequestHash["change"];
		if change == nil || change == ""
			puts "#{original}��̾�����ѹ����ޤ���"
			puts "<hr />"
			puts "<form method=\"GET\" action=\"#{ADMIN_SCRIPT}\">"
			puts "<input type=\"hidden\" name=\"state\" value=\"change_name\" />"
			puts "<input type=\"hidden\" name=\"mode\" value=\"file\" />"
			puts "<input type=\"hidden\" name=\"original\" value=\"#{original}\" />"
			puts "������̾����<input type=\"text\" name=\"change\" value=\"#{original}\" size=\"80\" /><br />"
			puts "<input type=\"submit\" value=\"�ѹ�\" />"
			puts "<input type=\"reset\" value=\"�᤹\" />"
			puts "</form>"
			return;
		else
			begin
				#�ޤ����ե�����̾��Ŭ���Ǥ��뤳�Ȥ��ǧ���롣
				original = original.dup.untaint();
				change = change.dup.untaint();
				original_t = UPLOAD_DIR+original;
				change_t = UPLOAD_DIR+change;
				dir = File.expand_path(original_t);
				if dir.index(UPLOAD_DIR) != 0
					raise "Security Error #{original}"
				end
				dir = File.expand_path(change_t);
				if dir.index(UPLOAD_DIR) != 0
					raise "Security Error #{change}"
				end
				#�ե����뤬¸�ߤ�������ѹ����ʤ���
				if FileTest.exist?(change_t)
					raise "#{change} is still exist."
				end
				#��äȤǤ��롣
				File.rename(original_t,change_t);
			rescue  => exc
				puts "#{original}=>#{change}<br />���Ԥ��ޤ�����<br />���顼��#{exc}"
			else
				puts "#{original}=>#{change}<br />�������ޤ�����"
			end
		end
	when "upload"
		if $PostHash.has_key?('upfile')
			bin =  $PostHash['upfile'][0];
			if bin.length == 0
				puts "�ե��������ꤷ�Ʋ�������"
			else
				if $PostHash.has_key?('filename')
					filename = $PostHash['filename'][0].read;
					filename = File.basename(filename);
				end
				if filename == "" || filename == nil
					filename = bin.original_filename;
				else
					ext = File.extname(filename);
					if ext == nil || ext == ""
						filename += File.extname(bin.original_filename)
					end
				end

				filename.untaint;
				up_file = UPLOAD_DIR + filename;
				cp_file = nil;
				exist = FileTest.exist?(up_file);
				if exist
					cp_file = UPLOAD_DIR + "[cp]" + filename;
					FileUtils.mv(up_file,cp_file);
				end
				file = open(up_file,"w");
				file.binmode;
				file.write(bin.read);
				file.flush;
				file.close;
				puts "<p>"
				puts "���åץ��ɤ��������ޤ�����<br />"
				puts "���åץ����衧#{up_file}"
				puts "</p>"
				if exist
					puts "<p>"
					puts "��äƤ���ե����뤬���ä��Τǡ����ԡ����Ƥ����ޤ�����<br />"
					puts "���ԡ��衧#{cp_file}"
					puts "</p>"
				end
			end
		end
	else
		puts "�ե���������Ԥ��ޤ����ե�������֤�������<br />"
		puts UPLOAD_DIR
		puts "�Ǥ���"
	end
end
	puts "<hr />"
	puts "�ե������������Ԥ��ޤ���"
	puts "<hr />"
	puts "<form method=\"POST\" action=\"#{ADMIN_SCRIPT}?mode=file&amp;state=upload\" enctype=\"multipart/form-data\">"
	puts "�ե�����̾��<input type=\"text\" name=\"filename\" size=\"20\" />"
	puts "�ե����롧<input type=\"file\" name=\"upfile\" size=\"20\" /><br />"
	puts "<input type=\"hidden\" name=\"state\" value=\"upload\" />"
	puts "<input type=\"submit\" value=\"Upload\" />"
	puts "<input type=\"reset\" value=\"Cancel\" />"
	puts "</form>"
	puts "<hr />"
	puts "�ե�����κ�����ե�����̾���ѹ���Ԥ��ޤ���"
	puts "<hr />"
	puts "<ul style=\"padding-left:0px;margin-left:0px\">"
	puts "<form method=\"GET\" action=\"#{ADMIN_SCRIPT}\">"
	puts "<input type=\"submit\" value=\"���\" />"
	puts "<input type=\"hidden\" name=\"state\" value=\"delete\" />"
	puts "<input type=\"hidden\" name=\"mode\" value=\"file\" />"
	Dir.foreach(UPLOAD_DIR) {|file|
		if file != "." && file != ".."
			puts "<li><input type=\"checkbox\" name=\"#{FILE_PREFIX}#{file}\" value=\"file\" />"
			bytes = File.stat(UPLOAD_DIR+file.untaint()).size;
			puts "[<a href=\"#{ADMIN_SCRIPT}?mode=file&amp;state=change_name&amp;original=#{file}\">�ѹ�</a>]<a href=\"#{UPLOAD_WEB}#{file}\">#{file}</a>(#{bytes})"
			puts "</li>"
		end
	}
	puts "</form>"
	puts "</ul>"
end

def showInfo()
	#
	puts "�ڡ�������"
	puts "<hr />"
	puts "<ul>"
	puts "<li>�ڡ���̾��#{WEB_TITLE}</li>"
	puts "<li>���ɥ쥹��<a href=\"#{WEB}\">#{WEB}</a></li>"
	puts "</ul>"
	
	#���������ꥹ��
	list = getAccessList(nil);
	cnt = list[0];
	if list[0] == nil
		cnt = "0";
	end
	puts "<hr />"
	puts "����������"
	puts "<hr />"
	puts "���ޤǤ�������������#{cnt}��Ǥ���"
	puts "<div style=\"height:500px;overflow:auto;\">"
	puts "<table width='2800'>"

	puts "<colgroup>"
	puts "<col span=\"1\" width=\"200\" />"
	puts "<col span=\"1\" width=\"80\" />"
	puts "<col span=\"1\" width=\"80\" />"
	puts "<col span=\"1\" width=\"160\" />"
	puts "<col span=\"1\" width=\"1280\" />"
	puts "<col span=\"1\" />"
	puts "</colgroup>"

	puts "<thead><tr>"
	puts "<th>������������</th>"
	puts "<th>No</th>"
	puts "<th>�ڡ���</th>"
	puts "<th>IP���ɥ쥹</th>"
	puts "<th>�桼���������������</th>"
	puts "<th>��󥯸�</th>"
	puts "</tr></thead>"

	puts "<tbody>"
	if list.size > 1
		list[1..list.size].reverse_each{|item|
			puts "<tr>"
			puts "<td>#{item[0]}</td>"
			puts "<td>#{item[2]}</td>"
			puts "<td>#{item[1]}</td>"
			puts "<td>#{item[3]}</td>"
			puts "<td>#{item[4]}</td>"
			puts "<td><a href=\"http://ime.nu/#{item[5]}\">#{item[5]}</a></td>"
			puts "</tr>"
		}
	end
	puts "</tbody>"

	puts "</table>"
	puts "</div>"
end

def showEdit(is_new)
	puts "<ul>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">��ɤ�</a></li>"
	puts "</ul>"
	id = "";
	title = "";
	content = "";
	original = "";
	if	$PostHash.has_key?("id") &&
		$PostHash.has_key?("title") &&
		$PostHash.has_key?("content") &&
		$PostHash.has_key?("original")
		id = $PostHash["id"][0].untaint();
		title = $PostHash["title"][0].untaint();
		original = $PostHash["original"][0].untaint();
		content = $PostHash["content"][0].untaint();
		rename = (original != id);
		if id.length == 0
			puts "���顼��ID������Ǥ��衪"
		elsif title.length == 0
			puts "���顼�������ȥ뤬����Ǥ��衪"
		else
			if	(rename || is_new) && $PageHash.has_key?(id)
				#�����⤷�����ѹ�������¸�ߤ��롣
				puts "���顼��ID:#{id}�Ϥ��Ǥ�¸�ߤ��ޤ���"
			else
				if rename && original.length > 0
					#�ѹ�
					page = PageContent.new(original,title,content);
					if page.change(id)
						puts "ID:#{original}����ID:#{id}�ؤ��ѹ����������ޤ�����"
						original = id;
					else
						puts "ID:#{original}����ID:#{id}�ؤ��ѹ��˼��Ԥ��ޤ�����"
					end
				else
					#�������⤷��������
					page = PageContent.new(id,title,content);
					if page.write()
						puts "�ڡ�������¸���������ޤ�����"
						original = id;
					else
						puts "�ڡ�������¸�˼��Ԥ��ޤ�����"
					end
				end
			end
		end

	else
		if(!is_new)
			id = $RequestHash["id"];
			if id == nil
				puts "id:#{id}<br />���Τ褦�ʥڡ�����¸�ߤ��ޤ���"
				return;
			end
			page = PageContent.read(id);
			id = page.getID;
			original = id;
			title = page.getTitle;
			content = page.getContent;
		end
	end
	puts "<hr />"
	puts "<form method=\"POST\" action=\"#{ADMIN_SCRIPT}?mode=edit\">"
	puts "�ե�����ID��<input type=\"text\" name=\"id\" value=\"#{id}\" /><br />"
	puts "�����ȥ롧<input type=\"text\" name=\"title\" value=\"#{title}\" /><br />"
	puts "<input type=\"hidden\" name=\"original\" value=\"#{original}\" />"
	puts "<textarea name=\"content\" cols=\"60\" rows = \"20\">#{content}</textarea>"
	puts "<br />"
	puts "<input type=\"submit\" value=\"��¸\" />"
	puts "<input type=\"reset\" value=\"�����᤹\" />"
	puts "</form>"
end

PAGE_PREFIX="page_";
def showContentIndex()
	puts "<form method=\"GET\" action=\"#{ADMIN_SCRIPT}\">"
	puts "<p>����#{$PageHash.size}�ĤΥڡ���������ޤ���</p>"
	puts "<input type=\"submit\" value=\"���\" />"
	puts "<input type=\"hidden\" name=\"mode\" value=\"delete\" />"
	puts "<hr />"
	puts "<ul>"
	$PageHash.each_pair {|key, value|
		puts "<li><input type=\"checkbox\" name=\"#{PAGE_PREFIX}#{key}\" value=\"true\" /><a href=\"#{ADMIN_SCRIPT}?mode=edit&amp;id=#{key}\">#{value}</a>(ID:#{key})</li>"
	}
	puts "</ul>"
	puts "</form>"
end

def showDelete()
	del_array = [];
	$RequestHash.each_pair {|key, value|
		if key.index(PAGE_PREFIX) == 0 && value == "true"
			page = key.slice(FILE_PREFIX.length..key.length);
			if $PageHash[page] != nil
				del_array.push(page);
			end
		end
	}
	if $RequestHash["checked"] == "true"
		puts "������ޤ�������̤ϰʲ��ΤȤ���Ǥ���"
		puts "<ul>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">��ɤ�</a>"
		puts "</ul>"
		puts "<hr />"
		puts "<ul>"
		del_array.each {|id|
			title = $PageHash[id];
			deleted = PageContent.delete(id);
			if deleted
				puts "<li>#{title}:������������ޤ���</li>"
			else
				puts "<li>#{title}:����˼��Ԥ��ޤ���</li>"
			end
		}
		puts "</ul>"
	else
		puts "�ʲ��Υڡ����������ޤ���������Ǥ�����"
		puts "<ul>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{$QueryString}&amp;checked=true\">�Ϥ�</a>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">������</a>"
		puts "</ul>"
		puts "<hr />"
		puts "<ul>"
		del_array.each {|id|
			puts "<li>#{$PageHash[id]}</li>"
		}
		puts "</ul>"
	end
end

def showHeader()
	puts <<-EOF
<?xml version="1.0" encoding="EUC-JP"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
 <meta http-equiv="Content-Style-Type" content="text/css" />
	EOF
	puts "<title>#{WEB_TITLE}���� - #{$Title}</title>"
	puts <<-EOF
<link rel="stylesheet" type="text/css" media="screen" href="
	EOF
	puts "#{SKIN_WEB}#{$CookieHash['color']}.css"
	puts <<-EOF
" charset="Shift_JIS"  />
</head>
<body>
<!--Header-->
<div id="header">
	EOF
	puts "<h1 class=\"title\">#{WEB_TITLE}���� - #{$Title}</h1>"
	puts <<-EOF
</div>
<div id="container">
<!--Left Box-->
	<div id="leftbox" class="menubar">
	EOF

end
def showMiddle()
	puts <<-EOF
	</div>
	<!--Center Box-->
	<div id="centerbox">
		<div id="contents">
	EOF
end
def showFooter()
	puts <<-EOF
		</div>
		<div id="footer">
				<hr />
				<div style="text-align:right">
				written by <a href="http://ledyba.ddo.jp/">PSI</a> version:1.0
				</div>
		</div>
	</div>
</div>
</body>
</html>
	EOF
end

main();