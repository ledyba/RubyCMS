#
# Rubyによる自前CMS (Pegasus用)
#

load("setting.rb");
require("module/util.rb");
require("module/lock_file.rb");
require("module/page_request.rb");
require("module/page_counter.rb");
require("module/page_formatter.rb");
require("module/page_reader.rb");

def main()
	init();
	write_html($RequestHash["page"]);
	close();
end

def init()
	initRequest({"page"=>"index"},{"color"=>DEFAULT_CSS},{},["color"]);
	checkCookie();
	InitPageIndex();
	initCounterModule();
end

def close()
	ClosePageIndex();
	closeCounterModule();
	closeRequest();
end

def checkCookie()
	color = $CookieHash["color"].untaint();
	if color != nil
		if !FileTest.exist?(SKIN_DIR+color+".css")
			$CookieHash["color"] = DEFAULT_CSS;
		end
	else
		$CookieHash["color"] = DEFAULT_CSS;
	end
end

def write_html(page_id)
	skin = read_skin();
	puts FilterText(skin,page_id,nil);
end

def read_skin()
	skin = "";
	f_lock(SKIN_FILE,FILE_LOCK_READ) {|file|
		skin = file.read();
	}
	return skin;
end

#実際の始まり。
main();
