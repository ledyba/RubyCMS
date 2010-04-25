<?xml version="1.0" encoding="EUC-JP"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
 <meta http-equiv="Content-Style-Type" content="text/css" />
 <title>&(WEB_TITLE) - &(page:title)</title>
 <link rel="stylesheet" type="text/css" media="screen" href="&(SKIN_CSS_FILE)" charset="Shift_JIS" />
</head>
<body>

<!--Header-->
<div id="header">
	<h1 class="title">&(WEB_TITLE) - &(page:title)</h1>
</div>
<div id="container">
	<!--Left Box-->
	<div id="leftbox" class="menubar">
	&(import:side:content)
	</div>
		<!--Center Box-->
	<div id="centerbox">
		<div id="contents">
		&(page:content)
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
