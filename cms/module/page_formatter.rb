
def formatText(body,show_page,now_page)
	body += "\n";

	ul_index = 0;#<ul>を数えるのに使う
	ol_index = 0;#<ul>を数えるのに使う
	p_before = true;#<p>を挿入するのに使う。
	p_started = false;#<p>を挿入するのに使う。
	body.gsub!(/.*?\n/) {|line|
		line.strip!;
		#リンク：[[]]
		line.gsub!(/\[\[.*?\]\]/){|element|
			element = element.slice!(2..element.length-3);
			cmd_arr = element.split(";");
			cmd = cmd_arr[0];
			if cmd_arr.length > 1
				option = " " << cmd_arr[1..cmd_arr.length].join(" ");
			else
				option = "";
			end
			index = cmd.index(":");
			if index != nil
				text = cmd.slice(0..index-1);
				text.strip!;
				link = cmd.slice(index+1..cmd.length);
				link.strip!;
				if (link =~ /&\(.*?\)/)==0	#&(なんとか)
				elsif (link =~ /:\/\//) != nil #アドレス候補
				elsif (link =~ /\@/) != nil	#メール候補
					if (link =~ /mailto:/) == nil
						link = "mailto:#{link}";
					end
				elsif link.include?(":")
					link = "&(#{link})"
				else
					if  link.include?(".")
						link = "&(link:file:#{link})"
					else
						link = "&(link:page:#{link})"
					end
				end
				element = "<a href=\"#{link}\"#{option}>#{text}</a>"
			else
				title = $PageTitleHash[cmd];
				if title != nil
					element = "<a href=\"&(link:page:#{title})\"#{option}>#{cmd}</a>"
				else
					element = "[[#{element}]]";
				end
			end
		}
		#はじめの文字で決まるコマンド
		line_ul_index = 0;
		line_ol_index = 0;
		p_flag = true;
		line_end = false;
		case line[0]
			when "-"[0]
				index = line.index(/[^\-]/,1);
				if index == nil
					index = line.length;
				end
				line = line.slice!(index..line.length);
				line_ul_index = index;
				line = "<li>#{line}</li>";
			when "+"[0]
				index = line.index(/[^\+]/,1);
				if index == nil
					index = line.length;
				end
				line = line.slice!(index..line.length);
				line_ol_index = index;
				line = "<li>#{line}</li>";
			when "#"[0]
				sharp_command = line.slice(1..line.length);
				#tmp = execSharpCmd(line.slice(1..line.length),show_page,now_page);
				#if tmp != nil
				#	line = tmp;
				#end
				line = "&(#{sharp_command})";
			when "*"[0]
				index = line.index(/[^\*]/,1);
				if index == nil
					index = line.length;
				end
				line = line.slice!(index..line.length);
				h_s = min(7,index+1).to_s;
				line = "<h#{h_s}>#{line}</h#{h_s}>";
			when "/"[0]
				index = line.index(/[^\/]/,1);
				if index == 2
					next
				end
			#終端
			when nil
				line_end = true;
			else
				p_flag = false;
		end
		if ul_index == nil
			ul_index = 0;
		end
		if line_ul_index == nil
			line_ul_index = 0;
		end
		if ol_index == nil
			ol_index = 0;
		end
		if line_ol_index == nil
			line_ol_index = 0;
		end

		if p_before == false && p_flag == true
			line = "</p>"+line
			p_started = false;
		elsif p_before == true && p_flag == false && !line_end
			line = "<p>"+line
			p_started = true;
		end

		if line_ol_index != 0
			line = exec_ol(ol_index,line_ol_index,line);
			line = exec_ul(ul_index,line_ul_index,line);
		else
			line = exec_ul(ul_index,line_ul_index,line);
			line = exec_ol(ol_index,line_ol_index,line);
		end

		ol_index = line_ol_index;#+か-が無ければ、これは0になる。
		ul_index = line_ul_index;#+か-が無ければ、これは0になる。
		p_before = p_flag;
		line = line + "\n";
	}
	if p_started
		body = body + "</p>";
	end
	return body;
end

def exec_ul(ul_index,line_ul_index,line)
	if ul_index > line_ul_index #減った
		if line_ul_index == 0
			time = ul_index - line_ul_index - 1;
			line = ("</ul></li>" * time)<<"</ul>"<<line;
		else
			time = ul_index - line_ul_index;
			line = ("</ul></li>" * time)<<line;
		end
	elsif ul_index < line_ul_index #増えた
		if ul_index == 0
			time = line_ul_index - ul_index-1;
			line = "<ul>"<<("<li><ul>" * time)<<line;
		else
			time = line_ul_index - ul_index;
			line = ("<li><ul>" * time)<<line;
		end
	end
	return line;
end
def exec_ol(ol_index,line_ol_index,line)
	if ol_index > line_ol_index #減った
		if line_ol_index == 0
			time = ol_index - line_ol_index - 1;
			line = ("</ol></li>" * time)<<"</ol>"<<line;
		else
			time = ol_index - line_ol_index;
			line = ("</ol></li>" * time)<<line;
		end
	elsif ol_index < line_ol_index #増えた
		if ol_index == 0
			time = line_ol_index - ol_index-1;
			line = "<ol>"<<("<li><ol>" * time)<<line;
		else
			time = line_ol_index - ol_index;
			line = ("<li><ol>" * time)<<line;
		end
	end
	return line;
end

#def execSharpCmd(text,show_page,now_page)
#	cmd = text.split(":");
#	case cmd[0]
#		when "comment"
#		else
#			return "&(#{text})"
#	end
#	return nil;
#end


