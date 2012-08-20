#!/usr/bin/ruby
# coding: utf-8

require 'rubygems'
gem 'oauth'
gem 'rubytter'
require 'oauth'
require 'rubytter'
require 'Win32API'
require 'tk'

# 本体
class Sirokuro
	# 定数の宣言
	CONSUMER_KEY = 'HOEkUDMKOs1LqQqmMbOCw'
	CONSUMER_SECRET = 'FF5319lvjRqpK7yFzYbXzmMYFWvJ58bjI2mAxyWORY'
	# 変数の宣言
	attr_accessor :consumer,
								:request_token,
								:access_token,
								:rubytter
								:file
								
	def initialize # 初期化
		@file = TokenFile.new
		@consumer = OAuth::Consumer.new(
			CONSUMER_KEY,
			CONSUMER_SECRET,
			:site => 'http://api.twitter.com'
		)

		@request_token = @consumer.get_request_token
		self.set_access_token(nil)
	end
	
	def open_browser # 認証画面にいってPINを取得してもらうためにブラウザを開いてもらう(windows依存?)
		shellexecute = Win32API.new('shell32.dll','ShellExecuteA',%w(p p p p p i),'i')
		shellexecute.call(0, 'open', @request_token.authorize_url, 0, 0, 1)
	end
	
	def set_access_token(oauth_verifier) # アクセストークンの生成
		if !oauth_verifier.nil? # PINの入力があるかどうか
			@access_token = @request_token.get_access_token(:oauth_verifier => oauth_verifier)
		elsif
			@access_token = OAuth::AccessToken.new(
				@consumer,
				@file.get_access_token,
				@file.get_access_secret
			)
		end
		
		self.create_rubytter # rubytterをnew
	end
	
	def create_rubytter # rubytterの生成
		if self.can_create_rubytter?
			@rubytter = OAuthRubytter.new(@access_token)
			@file.set_access_token(@access_token.token)
			@file.set_access_secret(@access_token.secret)
			@file.write_file
		end
	end

	def can_create_rubytter? # rubytterを生成できるか
		# アクセストークンがあって、tokenとsecretが空じゃない場合
		return !@access_token.token.nil? && @access_token.token != "" && !@access_token.secret.nil? && @access_token.secret != ""
	end
	
	def can_post? # rubytterがあってアクセストークンとかがあるか、それでpostできるか判定
		return can_create_rubytter? && !@rubytter.nil?
	end
	
end

# アクセストークン取得するためのいろいろ
class TokenFile
	#変数の宣言
	attr_accessor :path
								:access_token
								:access_secret
	
	def initialize # 初期化
		@path = "./tokens/tokens.txt" # 保存するファイルのディレクトリ
		
		if !Dir.exist?(File.dirname(@path)) # ディレクトリ作成
			Dir.mkdir(File.dirname(@path))
		end
		
		if File.exist?(@path) # アクセストークンの保存がしてあればそれぞれの値を取得
			file = File.open(@path, 'r:utf-8') { |f|
				line = f.readlines
				@access_token = line[0].chomp.encode('UTF-8')
				@access_secret = line[1].chomp.encode('UTF-8')
				f.close
			}
		end
		
	end
	
	def get_access_token # アクセストークンをnewするためにtokenを取得
		if File.exist?(@path)
			return "#{@access_token}"
		end
		
		return ""
	end
	
	def get_access_secret # アクセストークンをnewするためにsecretを取得
		if File.exist?(@path)
			return "#{@access_secret}"
		end
		
		return ""
	end
	
	def write_file # PINから得たアクセストークンもろもろの情報をファイルに保存
		File.open(@path, 'w+:utf-8') { |file|
			file.write "#{@access_token}\n#{@access_secret}"
			file.close
		}
	end
	
	def set_access_token(token) # アクセストークンのtokenをファイルに保存するためにset
		@access_token = token
	end
	
	def set_access_secret(secret) # アクセストークンのsecretをファイルに保存するためにset
		@access_secret = secret
	end
	
end


sirokuro = Sirokuro.new
txt = "アプリ認証"
isOpend = false

if sirokuro.can_post?
	txt = "ついーと"
	isOpend = true
end

textbox = TkText.new {
	wrap 'char'
	width 28
	height 3
	pack('fill' => 'both', 'anchor' => 'n', 'expand' => true)
}

TkButton.new {
	text txt
	command {
		if !sirokuro.can_post? && !isOpend
			sirokuro.open_browser
			text "PIN認証"
			isOpend = true
		elsif !sirokuro.can_create_rubytter? && !textbox.value.nil? && textbox.value != ""
			sirokuro.set_access_token(textbox.value)
			puts "set"
			if !sirokuro.access_token.nil?
				puts "to_post"
				text "ついーと"
				set_post(sirokuro.rubytter)
			end
		elsif sirokuro.can_post?
			if !textbox.value.nil? && textbox.value != ""
				sirokuro.rubytter.update(textbox.value.encode('UTF-8'))
				lastText = textbox.value.encode('UTF-8')
				textbox.clear
			end
		end
	}
	
	pack('fill' => 'both', 'anchor' => 's', 'expand' => true, 'side' => 'right')
}

def set_post(rubytter)
	TkButton.new {
		text "ホモ"
		command {
			rubytter.update("┌（┌ ＾o＾）┐ﾎﾓｫ…")
		}
		pack('fill' => 'both', 'anchor' => 's', 'expand' => true, 'side' => 'left')
	}
end

if sirokuro.can_post?
	set_post(sirokuro.rubytter) # widgetの生成の順番の関係
end

Tk.root.bind ['Control-z'], proc { # ctrl + z
	if sirokuro.can_post?
		textbox.value = lastText
	end
}

Tk.root.bind ['Control-Return'], proc { # ctrl + enter
	if sirokuro.can_post?
		sirokuro.rubytter.update(textbox.value.encode('UTF-8'))
		lastText = textbox.value.encode('UTF-8')
		textbox.clear
	end
}

# タイトル
Tk.root.title("しろくろ")
Tk.root.attributes('top', 1)
Tk.root.bg = '#000000'

Tk.mainloop