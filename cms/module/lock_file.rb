FILE_LOCK_READ = 1;
FILE_LOCK_WRITE = 2;
FILE_LOCK_RW = 3;

#ÉuÉçÉbÉNÇìnÇµÇƒèàóùÇ≈Ç´ÇÈ
def f_lock(file_path,mode)
	if mode != FILE_LOCK_WRITE && (!FileTest.exist?(file_path))
		return false;
	end
	lock_mode = nil;
	open_mode = nil;
	case mode
		when FILE_LOCK_READ
			lock_mode = File::LOCK_SH;
			open_mode = "r";
		when FILE_LOCK_WRITE
			lock_mode = File::LOCK_EX;
			open_mode = "w";
		when FILE_LOCK_RW
			lock_mode = File::LOCK_EX;
			open_mode = "r+";
		else
			return false;
	end
	state = true;
	begin
		file = open(file_path,open_mode);
		file.flock(File::LOCK_UN);
		file.flock(lock_mode);
		yield (file)
		if mode == FILE_LOCK_WRITE
			file.flush();
		elsif mode == FILE_LOCK_RW
			file.flush();
			file.truncate(file.tell);
		end
	rescue
		state = false;
	ensure
		file.flock(File::LOCK_UN);
		file.close;
	end
	return state;
end

