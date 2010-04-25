#
# Rubyによる自前CMS (Pegasus用)
# 管理プログラム
#

#自分の名前
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
	puts "<h1>属性変更</h1>"
	puts "<ul>"
	if $RequestHash.has_key?("color")
		query = getQuery("color","white");
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{query}\">白属性</a></li>"
		query = getQuery("color","black");
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{query}\">黒属性</a></li>"
	else
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{$QueryString}&amp;color=white\">白属性</a></li>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{$QueryString}&amp;color=black\">黒属性</a></li>"
	end
	puts "</ul>"
	puts "<h1>管理メニュー</h1>"
	puts "<ul>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}\">ページ情報</a></li>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=new\">新規ページ</a></li>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">ページ一覧表示</a></li>"
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=file\">ファイル</a></li>"
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
			$Title = "ページ情報"
			$Mode = 0;
		when "view"
			$Title = "一覧表示"
			$Mode = 1;
		when "new"
			$Title = "新規作成"
			$Mode = 2;
		when "delete"
			$Title = "削除"
			$Mode = 3;
		when "edit"
			$Title = "編集"
			$Mode = 4;
		when "file"
			$Title = "ファイル"
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
		puts "実行しました。結果は以下のとおりです。"
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
				puts "<li>#{file}：失敗しました。エラー：#{exc}</li>"
			else
				puts "<li>#{file}：成功しました。</li>"
			end
		}
		puts "</ul>"
	when "delete"
		puts "以下のファイルを削除します。よろしいですか？"
		puts "<ul>"
		ok_url = "#{ADMIN_SCRIPT}?"+ $QueryString.gsub("state=delete","state=ok");
		puts "<li><a href=\"#{ok_url}\">はい</a></li>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=file\">戻る</a></li>"
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
			puts "オリジナルの名前は・・・？"
			throw :out
		end
		change = $RequestHash["change"];
		if change == nil || change == ""
			puts "#{original}の名前を変更します。"
			puts "<hr />"
			puts "<form method=\"GET\" action=\"#{ADMIN_SCRIPT}\">"
			puts "<input type=\"hidden\" name=\"state\" value=\"change_name\" />"
			puts "<input type=\"hidden\" name=\"mode\" value=\"file\" />"
			puts "<input type=\"hidden\" name=\"original\" value=\"#{original}\" />"
			puts "新しい名前：<input type=\"text\" name=\"change\" value=\"#{original}\" size=\"80\" /><br />"
			puts "<input type=\"submit\" value=\"変更\" />"
			puts "<input type=\"reset\" value=\"戻す\" />"
			puts "</form>"
			return;
		else
			begin
				#まず、ファイル名が適正であることを確認する。
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
				#ファイルが存在する場合は変更しない。
				if FileTest.exist?(change_t)
					raise "#{change} is still exist."
				end
				#やっとできる。
				File.rename(original_t,change_t);
			rescue  => exc
				puts "#{original}=>#{change}<br />失敗しました。<br />エラー：#{exc}"
			else
				puts "#{original}=>#{change}<br />成功しました。"
			end
		end
	when "upload"
		if $PostHash.has_key?('upfile')
			bin =  $PostHash['upfile'][0];
			if bin.length == 0
				puts "ファイルを指定して下さい。"
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
				puts "アップロードに成功しました。<br />"
				puts "アップロード先：#{up_file}"
				puts "</p>"
				if exist
					puts "<p>"
					puts "被っているファイルがあったので、コピーしておきました。<br />"
					puts "コピー先：#{cp_file}"
					puts "</p>"
				end
			end
		end
	else
		puts "ファイル操作を行います。ファイルの置かれる先は<br />"
		puts UPLOAD_DIR
		puts "です。"
	end
end
	puts "<hr />"
	puts "ファイルの送信を行います。"
	puts "<hr />"
	puts "<form method=\"POST\" action=\"#{ADMIN_SCRIPT}?mode=file&amp;state=upload\" enctype=\"multipart/form-data\">"
	puts "ファイル名：<input type=\"text\" name=\"filename\" size=\"20\" />"
	puts "ファイル：<input type=\"file\" name=\"upfile\" size=\"20\" /><br />"
	puts "<input type=\"hidden\" name=\"state\" value=\"upload\" />"
	puts "<input type=\"submit\" value=\"Upload\" />"
	puts "<input type=\"reset\" value=\"Cancel\" />"
	puts "</form>"
	puts "<hr />"
	puts "ファイルの削除・ファイル名の変更を行います。"
	puts "<hr />"
	puts "<ul style=\"padding-left:0px;margin-left:0px\">"
	puts "<form method=\"GET\" action=\"#{ADMIN_SCRIPT}\">"
	puts "<input type=\"submit\" value=\"削除\" />"
	puts "<input type=\"hidden\" name=\"state\" value=\"delete\" />"
	puts "<input type=\"hidden\" name=\"mode\" value=\"file\" />"
	Dir.foreach(UPLOAD_DIR) {|file|
		if file != "." && file != ".."
			puts "<li><input type=\"checkbox\" name=\"#{FILE_PREFIX}#{file}\" value=\"file\" />"
			bytes = File.stat(UPLOAD_DIR+file.untaint()).size;
			puts "[<a href=\"#{ADMIN_SCRIPT}?mode=file&amp;state=change_name&amp;original=#{file}\">変更</a>]<a href=\"#{UPLOAD_WEB}#{file}\">#{file}</a>(#{bytes})"
			puts "</li>"
		end
	}
	puts "</form>"
	puts "</ul>"
end

def showInfo()
	#
	puts "ページ情報"
	puts "<hr />"
	puts "<ul>"
	puts "<li>ページ名：#{WEB_TITLE}</li>"
	puts "<li>アドレス：<a href=\"#{WEB}\">#{WEB}</a></li>"
	puts "</ul>"
	
	#アクセスリスト
	list = getAccessList(nil);
	cnt = list[0];
	if list[0] == nil
		cnt = "0";
	end
	puts "<hr />"
	puts "アクセスログ"
	puts "<hr />"
	puts "今までの総アクセス数は#{cnt}件です。"
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
	puts "<th>アクセス時刻</th>"
	puts "<th>No</th>"
	puts "<th>ページ</th>"
	puts "<th>IPアドレス</th>"
	puts "<th>ユーザ・エージェント</th>"
	puts "<th>リンク元</th>"
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
	puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">もどる</a></li>"
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
			puts "エラー：IDが空白ですよ！"
		elsif title.length == 0
			puts "エラー：タイトルが空白ですよ！"
		else
			if	(rename || is_new) && $PageHash.has_key?(id)
				#新規もしくは変更だが、存在する。
				puts "エラー：ID:#{id}はすでに存在します。"
			else
				if rename && original.length > 0
					#変更
					page = PageContent.new(original,title,content);
					if page.change(id)
						puts "ID:#{original}からID:#{id}への変更に成功しました。"
						original = id;
					else
						puts "ID:#{original}からID:#{id}への変更に失敗しました。"
					end
				else
					#新規、もしくは普通
					page = PageContent.new(id,title,content);
					if page.write()
						puts "ページの保存に成功しました。"
						original = id;
					else
						puts "ページの保存に失敗しました。"
					end
				end
			end
		end

	else
		if(!is_new)
			id = $RequestHash["id"];
			if id == nil
				puts "id:#{id}<br />そのようなページは存在しません。"
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
	puts "ファイルID：<input type=\"text\" name=\"id\" value=\"#{id}\" /><br />"
	puts "タイトル：<input type=\"text\" name=\"title\" value=\"#{title}\" /><br />"
	puts "<input type=\"hidden\" name=\"original\" value=\"#{original}\" />"
	puts "<textarea name=\"content\" cols=\"60\" rows = \"20\">#{content}</textarea>"
	puts "<br />"
	puts "<input type=\"submit\" value=\"保存\" />"
	puts "<input type=\"reset\" value=\"元に戻す\" />"
	puts "</form>"
end

PAGE_PREFIX="page_";
def showContentIndex()
	puts "<form method=\"GET\" action=\"#{ADMIN_SCRIPT}\">"
	puts "<p>現在#{$PageHash.size}個のページがあります。</p>"
	puts "<input type=\"submit\" value=\"削除\" />"
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
		puts "削除しました。結果は以下のとおりです。"
		puts "<ul>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">もどる</a>"
		puts "</ul>"
		puts "<hr />"
		puts "<ul>"
		del_array.each {|id|
			title = $PageHash[id];
			deleted = PageContent.delete(id);
			if deleted
				puts "<li>#{title}:削除に成功しました</li>"
			else
				puts "<li>#{title}:削除に失敗しました</li>"
			end
		}
		puts "</ul>"
	else
		puts "以下のページを削除します。よろしいですか？"
		puts "<ul>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?#{$QueryString}&amp;checked=true\">はい</a>"
		puts "<li><a href=\"#{ADMIN_SCRIPT}?mode=view\">いいえ</a>"
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
	puts "<title>#{WEB_TITLE}管理 - #{$Title}</title>"
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
	puts "<h1 class=\"title\">#{WEB_TITLE}管理 - #{$Title}</h1>"
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