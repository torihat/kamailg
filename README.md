# KamailG

KaMail for Gmail

## 注意

* このソフトウェアはまだ実験段階にあります。
* 実装されていない機能があったりします。
* ちゃんと動かない機能があったりします。
* 予告なく仕様が変わる場合があります。
* 将来的に実用レベルまで達するかどうかはわかりません。

## 概要

KaMailGは[xyzzy](http://www.jsdlab.co.jp/~kamei/)上でIMAP経由で[Gmail](http://mail.google.com/)を利用するメールリーダーのようななものです。

[Gmail](http://mail.google.com/)がIMAPをサポートしたので、試しに作ってみた程度のものです。

## 動作環境

* [xyzzy](http://xyzzy-022.github.io/)-0.2.2.248 以降
* [junk-library](http://www7a.biglobe.ne.jp/~hat/xyzzy/dl.html#junk-library)/0.0.0.6 以降
* [browser.dll拡張版](http://www.osk.3web.ne.jp/~usitukai/) (option)
* [browserex](http://ohkubo.s53.xrea.com/xyzzy/#browserex) (option)
* [統合アーカイバ・プロジェクト](http://www.csdinc.co.jp/archiver/)の各種DLL (option)

動作には、[Gmail](http://mail.google.com/)のアカウントが必要です。

## インストール

[NetInstaller](http://www7a.biglobe.ne.jp/~hat/xyzzy/dl.html#NetInstaller)でインストールするか、
[ダウンロード](http://www7a.biglobe.ne.jp/~hat/xyzzy/dl.html#KaMailG)したアーカイブを system-root 以下に展開してください。

## 設定

ni-autoload を有効にしていない場合は、以下を .xyzzy または siteinit.l に書いてください。

```
(autoload 'kamailg "kamailg/defs" t)
(autoload 'kamailg-toggle "kamailg/defs" t)
```

設定は、site-lisp/kamailg/config.l.sample を ~/.kamailg/config.l にコピーして必要箇所を記入してください。

## 起動

xyzzy で以下を実行します。

```
M-x kamailg
```

いったん引っ込めたり、また出したりする場合は以下を実行します。

```
M-x kamailg-toggle
```

これらはデフォルトではキーに割り当てられていませんので、必要に応じて設定してください。

## 検索

<dl>
	<dt>通常検索 （キー：<strong>/</strong>）</dt>
	<dd>
		全文検索条件と属性検索条件とをスペースで区切って入力します。条件は全てAND条件になります。<br>
		全文検索条件・属性検索条件のどちらか一つは必ず入力する必要があります。
		<ul>
			<li>
				普通に単語をスペース区切りで入力するとAND検索になります。
				<pre>例："xyzzy" と "windows" を含むメールを検索
<span class="prompt">Query:</span> xyzzy windows</pre>
			</li>
			<li>
				日付の範囲指定をする場合は以下のように指定します。
				<pre>例："xyzzy" を含んだ2006/01/01 以降のメールを検索
<span class="prompt">Query:</span> xyzzy date&gt;=20060101</pre>
				<pre>例："xyzzy" を含んだ2006年2月のメールを検索
<span class="prompt">Query:</span> xyzzy date&gt;=20060201 date&lt;20060301</pre>
			</li>
			<li>
				日付の範囲指定は現在からの相対指定を行うこともできます。
				<pre>例："xyzzy" を含んだ3日以内のメールを検索
<span class="prompt">Query:</span> xyzzy date:3d</pre>
				<pre>例："xyzzy" を含んだ1週間以内のメールを検索
<span class="prompt">Query:</span> xyzzy date:1w</pre>
				<pre>例："xyzzy" を含んだ1年前以前のメールを検索
<span class="prompt">Query:</span> xyzzy date:-1y</pre>
			</li>
			<li>
				日付以外の属性の検索を行う場合。
				<pre>例：xyzzy@example.com から来たメールを検索（From に xyzzy@example.com を含むメール）
<span class="prompt">Query:</span> from:xyzzy@example.com</pre>
				<pre>例：Subjectに xyzzy を含むメールを検索
<span class="prompt">Query:</span> subject:xyzzy</pre>
				<pre>例：スター付きのメールを検索
<span class="prompt">Query:</span> flag:flagged</pre>
				<pre>例：未読のメールを検索
<span class="prompt">Query:</span> flag:unseen</pre>
				<pre>例：既読のメールを検索
<span class="prompt">Query:</span> flag!unseen</pre>
			</li>
		</ul>
	</dd>
</dl>

## キーバインド

### summary buffer でのキーバインド

<table class="data_list">
	<tr><th rowspan=1>アカウント</th><td align="center"><strong>H</strong></td><td>アカウント選択</td></tr>
	<tr><th rowspan=7>フォルダ</th><td align="center"><strong>e</strong></td><td>フォルダ選択</td></tr>
	<tr><td align="center"><strong>g i</strong></td><td>INBOXを開く</td></tr>
	<tr><td align="center"><strong>g d</strong></td><td>Draftsを開く</td></tr>
	<tr><td align="center"><strong>g s</strong></td><td>Starredを開く</td></tr>
	<tr><td align="center"><strong>g r</strong></td><td>フォルダ一覧を更新</td></tr>
	<tr><td align="center"><strong>g a</strong></td><td>フォルダを作成</td></tr>
	<tr><td align="center"><strong>g x</strong></td><td>フォルダを削除</td></tr>
	<tr><th rowspan=4>メール一覧</th><td align="center"><strong>G</strong></td><td>一覧のメールを受信</td></tr>
	<tr><td align="center"><strong>R</strong></td><td>一覧を更新</td></tr>
	<tr><td align="center"><strong>→</strong></td><td>次のn件を表示</td></tr>
	<tr><td align="center"><strong>←</strong></td><td>前のn件を表示</td></tr>
	<tr><th rowspan=9>メール表示<td align="center"><strong>Enter/Space</strong></td><td>メールを表示/スクロール</td></tr>
	<tr><td align="center"><strong>Tab</strong></td><td>次の未読メールを表示</td></tr>
	<tr><td align="center"><strong>j</strong></td><td>次の行のメールを表示</td></tr>
	<tr><td align="center"><strong>k</strong></td><td>前の行のメールを表示</td></tr>
	<tr><td align="center"><strong>n</strong></td><td>次の行へ移動</td></tr>
	<tr><td align="center"><strong>p</strong></td><td>前の行へ移動</td></tr>
	<tr><td align="center"><strong>w</strong></td><td>添付ファイルを保存</td></tr>
	<tr><td align="center"><strong>W</strong></td><td>添付ファイルを保存して実行</td></tr>
	<tr><td align="center"><strong>J</strong></td><td>partialメッセージを結合して表示</td></tr>
	<tr><th rowspan=6>検索</th><td align="center"><strong>/</strong></td><td>検索</td></tr>
	<tr><td align="center"><strong>h</strong></td><td>検索履歴から選択</td></tr>
	<tr><td align="center"><strong>? f</strong></td><td>メールの送信者で検索</td></tr>
	<tr><td align="center"><strong>? F</strong></td><td>メールの送信者でメッセージを検索</td></tr>
	<tr><td align="center"><strong>? s</strong></td><td>メールの件名で検索</td></tr>
	<tr><td align="center"><strong>? m</strong></td><td>メールのIn-Reply-ToもしくはMessage-Idで検索</td></tr>
	<tr><th rowspan=4>マーク</th><td align="center"><strong>x</strong></td><td>マークを付ける／外す</td></tr>
	<tr><td align="center"><strong>m a</strong></td><td>全てマークする</td></tr>
	<tr><td align="center"><strong>m c</strong></td><td>全てマークを外す</td></tr>
	<tr><td align="center"><strong>m /</strong></td><td>ヘッダーの条件を指定してマークする</td></tr>
	<tr><th rowspan=5>メール作成</th><td align="center"><strong>c</strong></td><td>メールを新規作成</td></tr>
	<tr><td align="center"><strong>r</strong></td><td>メールに返信</td></tr>
	<tr><td align="center"><strong>a</strong></td><td>全員に返信</td></tr>
	<tr><td align="center"><strong>f</strong></td><td>メールを転送</td></tr>
	<tr><td align="center"><strong>F</strong></td><td>メールを添付ファイルとして転送</td></tr>
	<tr><th rowspan=4>メール処理</th><td align="center"><strong>y</strong></td><td>メールをアーカイブ</td></tr>
	<tr><td align="center"><strong>I</strong></td><td>メールをinboxへ移動</td></tr>
	<tr><td align="center"><strong>!</strong></td><td>メールをspamへ移動</td></tr>
	<tr><td align="center"><strong>#</strong></td><td>メールをtrashへ移動</td></tr>
	<tr><th rowspan=1>アドレス帳</th><td align="center"><strong>C-c a</strong></td><td>送信者をアドレス帳に登録</td></tr>
	<tr><th rowspan=6>その他</th><td align="center"><strong>右クリック</strong></td><td>ポップアップメニューを表示</td></tr>
	<tr><td align="center"><strong>[</strong></td><td>サーバーに接続</td></tr>
	<tr><td align="center"><strong>]</strong></td><td>サーバー接続を終了</td></tr>
	<tr><td align="center"><strong>F1</strong></td><td>README.mdを表示</td></tr>
	<tr><td align="center"><strong>q</strong></td><td>メッセージを閉じる/終了</td></tr>
	<tr><td align="center"><strong>Q</strong></td><td>終了</td></tr>
</table>

### message buffer でのキーバインド

<table class="data_list">
	<tr><th rowspan=3>メール表示<td align="center"><strong>Space</strong></td><td>メールをスクロール/閉じる</td></tr>
	<tr><td align="center"><strong>s</strong></td><td>添付ファイルを保存</td></tr>
	<tr><td align="center"><strong>x</strong></td><td>添付ファイルを保存して実行</td></tr>
	<tr><th rowspan=5>メール作成</th><td align="center"><strong>c</strong></td><td>メールを新規作成</td></tr>
	<tr><td align="center"><strong>r</strong></td><td>メールに返信</td></tr>
	<tr><td align="center"><strong>a</strong></td><td>全員に返信</td></tr>
	<tr><td align="center"><strong>f</strong></td><td>メールを転送</td></tr>
	<tr><td align="center"><strong>F</strong></td><td>メールを添付して転送</td></tr>
	<tr><th>その他</th><td align="center"><strong>q/u</strong></td><td>メッセージを閉じる</td></tr>
</table>

### draft buffer でのキーバインド

<table class="data_list">
	<tr><th rowspan=12>メール編集<td align="center"><strong>Enter</strong></td><td>カーソル位置の内容を編集</td></tr>
	<tr><td align="center"><strong>d</strong></td><td>現在位置の内容を削除</td></tr>
	<tr><td align="center"><strong>f</strong></td><td>Fromを選択</td></tr>
	<tr><td align="center"><strong>s</strong></td><td>Subjectを編集</td></tr>
	<tr><td align="center"><strong>e</strong></td><td>本文を編集</td></tr>
	<tr><td align="center"><strong>t</strong></td><td>Toを追加</td></tr>
	<tr><td align="center"><strong>T</strong></td><td>Toを追加（ダイアログ）</td></tr>
	<tr><td align="center"><strong>c</strong></td><td>Ccを追加</td></tr>
	<tr><td align="center"><strong>C</strong></td><td>Ccを追加（ダイアログ）</td></tr>
	<tr><td align="center"><strong>b</strong></td><td>Bccを追加</td></tr>
	<tr><td align="center"><strong>B</strong></td><td>Bccを追加（ダイアログ）</td></tr>
	<tr><td align="center"><strong>m</strong></td><td>Content-Typeを編集</td></tr>
	<tr><th rowspan=3>添付<td align="center"><strong>a</strong></td><td>ファイルを添付（複数選択可）</td></tr>
	<tr><td align="center"><strong>C-u a</strong></td><td>ファイルを圧縮して添付</td></tr>
	<tr><td align="center"><strong>A</strong></td><td>フォルダを圧縮して添付</td></tr>
	<tr><th rowspan=3>送信・保存</th><td align="center"><strong>C-c C-c</strong></td><td>メールを送信</td></tr>
	<tr><td align="center"><strong>C-x C-s</strong></td><td>メールを保存</td></tr>
	<tr><td align="center"><strong>q</strong></td><td>閉じる</td></tr>
</table>

### edit buffer でのキーバインド

<table class="data_list">
	<tr><th rowspan=1>編集</th><td align="center"><strong>M-Insert</strong></td><td>署名を挿入</td></tr>
	<tr><th rowspan=2>保存</th><td align="center"><strong>C-x C-s</strong></td><td>保存して編集を終了</td></tr>
	<tr><td align="center"><strong>C-c q</strong></td><td>保存せずに編集を終了</td></tr>
</table>

### signature buffer でのキーバインド

<table class="data_list">
	<tr><th rowspan=4>署名</th><td align="center"><strong>Enter</strong></td><td>署名を挿入</td></tr>
	<tr><td align="center"><strong>j/n</strong></td><td>次の署名</td></tr>
	<tr><td align="center"><strong>k/p</strong></td><td>次の署名</td></tr>
	<tr><td align="center"><strong>q</strong></td><td>署名選択を閉じる</td></tr>
</table>

その他
----
### browser.dll、browserex を利用したHTML表示

config.l で 設定を行うと、summary buffer で以下のキーバインドが有効になります。

<table class="data_list">
	<tr><th rowspan=2>HTMLメール表示</th><td align="center"><strong>v</strong></td><td>HTMLメールを browser.dll で表示</td></tr>
	<tr><td align="center"><strong>q</strong></td><td>browserを閉じる/メッセージを閉じる/終了</td></tr>
</table>

### stunnelの設定例

stunnel.confの例

```
cert = stunnel.pem
;key = stunnel.pem

; Some performance tunings
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

; Use it for client mode
client = yes

; Service-level configuration

[imaps]
accept  = 993
connect = imap.gmail.com:993

[ssmtp]
accept  = 465
connect = smtp.gmail.com:465</pre>
```

## ChangeLog

* 2013/05/30: 0.0.0.2
	* xyzzy-0.2.2.248 のSSLサポートを受けてSSL対応。
* 2007/12/23: 0.0.0.1alpha
	* 初版
