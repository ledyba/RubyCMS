require "fileutils.rb"
require "cgi.rb"

MAX_COUNTER_LOG = 100;

$CountedHash;
$NoCount = false;
$Referer = nil;
$UserAgent = nil;
$NowTime = nil;
def initCounterModule()
	#ログ表示用
	if ENV.include?('HTTP_REFERER')
		$Referer = CGI::escapeHTML(ENV['HTTP_REFERER'].dup);
	else
		$Referer = "(none)";
	end
	if ENV.include?('HTTP_USER_AGENT')
		$UserAgent = CGI::escapeHTML(ENV['HTTP_USER_AGENT'].dup);
	else
		$UserAgent = "(none)";
	end
	$NowTime = Time.now.strftime("%a %b %d %H:%M:%S");

	#初期化
	$CountedHash = Hash::new;
	$CountedHash.default = false;
	if $Referer!= nil && ($Referer.index(WEB))==0
		$NoCount = true;
	else
		$NoCount = false;
	end

end

def closeCounterModule()
	$CountedHash = nil;
	$NoCount = nil;
	$Referer = nil;
	$UserAgent = nil;
	$NowTime = nil;
end


def execCounterCmd(page_id,show_page,now_page)
	if $CountedHash[page_id]#すでに表示したカウンタはもう表示しない
		return nil;
	else
		$CountedHash[page_id] = true;
	end
	if page_id == "/"
		page_id = show_page;
	end
	return execCounterFile(page_id,show_page);
end

def getAccessList(page_id)
	if page_id == nil
		file_path = COUNTER_LOG_FILE;
	else
		file_path = PAGE_DIR + "count_"+page_id+".rb";
	end
	list = [];
	state = f_lock(file_path,FILE_LOCK_READ){|file|
		while !file.eof?
			line = file.readline;
			line.strip!
			list.push(line.split("<>"));
		end
	}
	return list;
end

def execCounterFile(page_id,show_page)
	if !(page_id == nil || $PageHash.has_key?(page_id))
		return nil;
	end
	if page_id == nil
		file_path = COUNTER_LOG_FILE;
		page_id = show_page;
	else
		page_id.untaint();
		file_path = PAGE_DIR + "count_"+page_id+".rb";
	end
	count = "Unable to rw counter file.";
	log = nil;

	FileUtils.touch(file_path);
	f_lock(file_path,FILE_LOCK_RW){|file|
		log = file.readlines;
		if log.size == 0#空配列＝空ファイル
			count = 1;
		else
			count = log[0].strip.to_i;
			if !$NoCount
				count+=1;
			end
		end
		count = count.to_s;
		if !$NoCount
			file.seek(0,IO::SEEK_SET);
			file.puts count;
			if log.size > 1
				log[max(1,log.size-MAX_COUNTER_LOG)..log.size].each{|item|
					file.puts item;
				}
			end
			file.puts "#{$NowTime}<>#{page_id}<>#{count}<>#{ENV['REMOTE_ADDR']}<>#{$UserAgent}<>#{$Referer}"
		end
	}
	return count;
end
