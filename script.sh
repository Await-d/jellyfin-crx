#!/bin/bash

read -p "请输入 Jellyfin 容器名称:" name
echo "程序安装中...（如长时间未响应或下载失败，请检查网络是否能连接Github）"

# 在容器内创建文件夹
docker exec -it  $name rm -rf /jellyfin/jellyfin-web/jellyfin-crx/
docker exec -it  $name mkdir -p /jellyfin/jellyfin-web/jellyfin-crx/

#定义github下载路径
github="https://raw.githubusercontent.com/Await-d/jellyfin-crx/master"
gitee="https://gitee.com/await29/jellyfin-crxj/raw/master"

# 下载所需文件到系统
echo "正在下载缓存文件，请稍等... ..."
wget -q --no-check-certificate $github/static/css/style.css -O style.css || $gitee/static/css/style.css -O style.css  || { echo "错误：无法下载"; exit 1; }
wget -q --no-check-certificate $github/static/js/common-utils.js -O common-utils.js || $gitee/static/js/common-utils.js -O common-utils.js || { echo "错误：无法下载"; exit 1; }
wget -q --no-check-certificate $github/static/js/jquery-3.6.0.min.js -O jquery-3.6.0.min.js || $gitee/static/js/jquery-3.6.0.min.js -O jquery-3.6.0.min.js || { echo "错误：无法下载"; exit 1; }
wget -q --no-check-certificate $github/static/js/md5.min.js -O md5.min.js || $gitee/static/js/md5.min.js -O md5.min.js || { echo "错误：无法下载"; exit 1; }
wget -q --no-check-certificate $github/content/main.js -O main.js || $gitee/content/main.js -O main.js || { echo "错误：无法下载"; exit 1; }

# 从系统复制文件到容器内
docker cp style.css $name:/jellyfin/jellyfin-web/jellyfin-crx/
docker cp common-utils.js $name:/jellyfin/jellyfin-web/jellyfin-crx/
docker cp jquery-3.6.0.min.js $name:/jellyfin/jellyfin-web/jellyfin-crx/
docker cp md5.min.js $name:/jellyfin/jellyfin-web/jellyfin-crx/
docker cp main.js $name:/jellyfin/jellyfin-web/jellyfin-crx/

# 定义安装程序
function Installing() {
	# 读取index.html文件内容
	content=$(cat index.html)

	# 定义要插入的代码
	code='<link rel="stylesheet" id="theme-css" href="./jellyfin-crx/style.css" type="text/css" media="all" />\n<script src="./jellyfin-crx/common-utils.js"></script>\n<script src="./jellyfin-crx/jquery-3.6.0.min.js"></script>\n<script src="./jellyfin-crx/md5.min.js"></script>\n<script src="./jellyfin-crx/main.js"></script>'

	# 在</head>之前插入代码
	new_content=$(echo -e "${content/<\/head>/$code<\/head>}")

	# 将新内容写入index.html文件
	echo -e "$new_content" > index.html
	# 覆盖容器内取index.html文件
	docker cp ./index.html $name:/jellyfin/jellyfin-web/
}

# 先复制一份到系统内
docker cp $name:/jellyfin/jellyfin-web/index.html ./

# 检查index.html是否包含jellyfin-crx
if grep -q "jellyfin-crx" index.html; then
    docker cp $name:/jellyfin/jellyfin-web/bak/index.html ./
    Installing
    echo "成功！Index.html 已重新修改！"
else
    docker cp $name:/jellyfin/jellyfin-web/index.html ./
    # 备份
    docker exec -it  $name mkdir -p /jellyfin/jellyfin-web/bak/
    docker cp ./index.html $name:/jellyfin/jellyfin-web/bak/
    Installing
    echo "成功！Index.html 首次安装！"
fi
#打印当前目录地址
rm -rf style.css common-utils.js jquery-3.6.0.min.js md5.min.js main.js index.html script.sh
# 判断是否删除成功 判定条件 style.css 是否存在
if [ -f style.css ]; then
    echo "删除失败！请手动删除！"
    echo "当前下载目录地址：$(pwd)"
    echo "手动删除指令为：cd $(pwd) && rm -rf style.css common-utils.js jquery-3.6.0.min.js md5.min.js main.js index.html script.sh"
else
    echo "请刷新Jellyfin首页查看！"
fi

