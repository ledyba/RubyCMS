require("cgi.rb");

$RequestHash = nil;
$CookieHash = nil;
$PostHash = nil;
$QueryString = nil;
def initQuery(hash)
	hash.default = nil;
	$QueryString = "";
	if ENV.has_key?( 'QUERY_STRING' )
		$QueryString = ENV['QUERY_STRING'].dup;
		$QueryString.gsub!(/($&+)|(^&+)/,"");
		$QueryString.gsub!(/&&+/,"&");
		$QueryString.gsub!("&","&amp;")
	end
	$QueryString.freeze;#書き換え禁止
	cmd = $QueryString.split("&amp;");
	cmd.each(){|text|
		index = text.index("=");
		if index == nil
			next
		end
		key = text.slice(0..index-1);
		value = text.slice(index+1..text.length);
		hash.store(CGI.unescape(key.chomp),CGI.unescape(value.chomp));
	}
	$RequestHash = hash;
	return $RequestHash;
end

def closeRequest()
	$RequestHash = nil;
	$CookieHash = nil;
	$PostHash = nil;
	$QueryString = nil;
end

def getQuery(key,new)
	tmp = $QueryString + "&amp;";
	tmp.gsub!(/#{key}=.*?&amp;/,'');
	return tmp+"#{key}=#{new}";
end

def initCookie(cgi,cookie)
	$CookieHash = cookie;
	$CookieHash.default = nil;
	hash = cgi.cookies;
	new_hash = Hash::new;
	hash.each_pair {|key, value|
		v = value.value[0].to_s;
		if v != nil
			new_hash[CGI.unescape(key.chomp)] = CGI.unescape(CGI.unescape(v));
		end
	}
	$CookieHash.update(new_hash);
	return $CookieHash;
end

def initPost(cgi,post)
	$PostHash = post;
	$PostHash.default = nil;
	$PostHash.update(cgi.params);
	return $PostHash;
end

def initRequest(	query_hash = Hash::new,
					cookie_hash = Hash::new,
					post_hash = Hash::new,
					cookie_writing = []
				)
	req = Apache.request
	req.content_type = "text/html; charset=EUC-JP"
#	req.content_type = "application/xhtml+xml; charset=EUC-JP"
		query_hash.default = nil;
		cookie_hash.default = nil;
		cgi = CGI.new;
		query_hash = initQuery(query_hash);
		cookie_hash = initCookie(cgi,cookie_hash);
		#クッキーに登録すべきクエリを検索
		query_hash.each_pair {|key, value|
			cookie_writing.each(){|writing|
				if key == writing
					cookie_hash[key] = value;
				end
			}
		}
		#クッキー書き込み
		cookie_hash.each_pair {|key, value|
			cookie_writing.each(){|writing|
				if key == writing
					cookie = Apache::Cookie.new(req,
						:name => key,
						:value => value
					);
					cookie.expires = "+3M";
					cookie.bake();
				end
			}
		}
	req.send_http_header();
	post_hash = initPost(cgi,post_hash);
end

