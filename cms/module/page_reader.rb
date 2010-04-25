
INDEX_PARSER = "<>";

$PageHash = nil;
$PageTitleHash = nil;
$PageReader_rewrited = nil;
def InitPageIndex()
	$PageHash = Hash.new;
	$PageHash.default = nil;

	$PageTitleHash = Hash.new;
	$PageTitleHash.default = nil;

	$PageReader_rewrited = false;

	f_lock(PAGE_INDEX,FILE_LOCK_READ){ |file|
		while !file.eof?
			line=file.readline()
			line.strip!;
			idx = line.split(INDEX_PARSER);
			$PageHash.store(idx[0],idx[1]);
			$PageTitleHash.store(idx[1],idx[0]);
		end
	}
end
def ClosePageIndex()
	if $PageReader_rewrited
		f_lock(PAGE_INDEX,FILE_LOCK_WRITE){|file|
			$PageHash.each_pair {|key, value|
				file.puts(key + INDEX_PARSER + value);
			}
		}
	end
	#変数開放
	$PageHash = nil;
	$PageTitleHash = nil;
	$PageReader_rewrited = nil;
end

#ページコンテンツのクラス定義
class PageContent
	def initialize(id,title,content)
		@ID = id;
		@Title = title;
		@Content = content;
	end
	def getID()
		return @ID
	end
	def getTitle()
		return @Title
	end
	def setTitle(title = nil)
		if title != nil
			@Title = title;
		end
	end
	def getContent()
		return @Content
	end
	def setContent(content = nil)
		if content != nil
			@Content = content;
		end
	end
	def write()
		if check_data()
			return false;
		end
		#ページファイル自体への書き込み
		filename = PAGE_DIR + ("page_"<<@ID<<".rb");
		state = f_lock(filename,FILE_LOCK_WRITE){|file|
			file.puts(@Content);
		}
		if !state
			return false;
		end
		#ハッシュへ追加
		$PageHash[@ID] = @Title;
		$PageTitleHash[@Title] = @ID;
		$PageReader_rewrited = true;
		return true;
	end
	def change(id)
		if check_data() || id.index(INDEX_PARSER) != nil
			return false;
		end
		next_name = PAGE_DIR + ("page_"<<id<<".rb");
		next_count = PAGE_DIR + ("count_"<<id<<".rb");
		now_name = PAGE_DIR + ("page_"<<@ID<<".rb");
		now_count = PAGE_DIR + ("count_"<<@ID<<".rb");
		if FileTest.exist?(next_name)
			#すでに存在する＝書き込めないよ！！！１１１
			return false;
		end
		#ハッシュ変更
		$PageHash.delete(@ID);
		@ID = id;
		$PageTitleHash[@Title] = @ID;
		$PageHash[@ID] = @Title;
		$PageReader_rewrited = true;
		#ファイル移動
		File.rename(now_name,next_name);
		File.rename(now_count,next_count);
		return true;
	end
	def check_data()
		if @ID.index(INDEX_PARSER) != nil || @Title.index(INDEX_PARSER) != nil
			return true;
		end
		return false;
	end
#ここからクラスメソッド
	def PageContent.read(id)
		title = $PageHash[id];
		if title != nil
			id.untaint;#見つかったのだから浄化
			content = "";
			f_lock(PAGE_DIR + ("page_"<<id<<".rb"),FILE_LOCK_READ){|file|
				content = file.read();
			}
			return PageContent.new(id,title,content);
		end
		return PageContent.new("-1","Page not found","Page not found.");
	end
	def PageContent.delete(id)
		#見つかったので削除
		title = $PageHash[id];
		if title != nil
			id.untaint;#見つかったので浄化
			#ハッシュから削除
			$PageTitleHash.delete(title);
			$PageHash.delete(id);
			#ファイルから削除
			page_name = PAGE_DIR + ("page_" << id << ".rb");
			if FileTest.exist?(page_name)
				File.delete(page_name);
			end
			#カウンタファイルも削除しよー。
			page_name = PAGE_DIR + ("count_" << id << ".rb");
			if FileTest.exist?(page_name)
				File.delete(page_name);
			end
			$PageReader_rewrited = true;
			return true;
		end
		return false;
	end
end

def FilterText(text,show_page,now_page)
	if now_page != nil#スキンでない
		text = formatText(text,show_page,now_page);
	end
	text.gsub!(/&\(.*?\)/){|matched|
		tmp = doLinkCmd(matched.slice(2..matched.length-2),show_page,now_page);
		if(tmp == nil)
			matched = matched;
		else
			matched = tmp;
		end
	}
	return text;
end

REWRITE_TEXT = {
	"WEB_TITLE"=>WEB_TITLE,
	"WEB_ADDRESS"=>WEB,
	"SCRIPT_ADDRESS"=>SCRIPT_ADDRESS,
};
REWRITE_TEXT.default = nil;
def doLinkCmd(text,show_page,now_page)
	cmd = text.split(/:/);
	length = cmd.length;
	case cmd[0]
		#インポート関連
		when "page"
			if cmd[1] == "content"
				if now_page != nil;#スキンでなければ使えない
					return nil;
				end
				page = PageContent.read(show_page);
				return FilterText(page.getContent,show_page,show_page);
			elsif cmd[1] == "title"
				title = $PageHash[show_page];
				if title == nil
					title = "Page not found"
				end
				return title;
			end
		when "import"
			if cmd[2] == "content"
				if now_page == cmd[1]
					return nil
				end
				#開発者しか使えないので、任せる。
				cmd[1].untaint;
				page = PageContent.read(cmd[1]);
				if page == nil
					return nil;
				end
				return FilterText(page.getContent,show_page,cmd[1]);
			elsif cmd[2] == "title"
				title = $PageHash[cmd[1]];
				if title == nil
					title = "Page not found"
				end
				return title;
			end
		when "link"
			if length <= 3
				case cmd[1]
					when "color"
						return WEB+$RequestHash["page"]+"/?color="+cmd[2];
					when "page"
						return WEB+cmd[2]+"/";
					when "file"
						return UPLOAD_WEB+cmd[2];
				end
			elsif length <=4
				case cmd[1]
					when ""
				end
			end
		when "counter"
			return execCounterCmd(cmd[1],show_page,now_page);
		#以下定数
		when "SKIN_CSS_FILE"
			return SKIN_WEB+$CookieHash["color"]+".css";
		else
			return REWRITE_TEXT[cmd[0]];
	end
	return nil;
end
