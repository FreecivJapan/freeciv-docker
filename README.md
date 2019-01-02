# freecivを動かすdockerファイルとその補助ファイル群です

## 使用前に
docker-homeのパーミッションを777に変更すること。


## ビルド方法
$ sudo docker build -t sensu-watson/freeciv .

## 起動方法
$ sudo docker run -v [YourFilePath]/docker-home:/home/freeciv -v [YourFilePath]/rulesets:/usr/local/share/freeciv/ --rm -it --name freeciv5556 -d -p 5556:5556 sensu-watson/freeciv

## 非公開サーバとしての起動方法
$ sudo docker run -v [YourFilePath]/docker-home:/home/freeciv -v [YourFilePath]/rulesets:/usr/local/share/freeciv/ --rm -it --name freeciv5556 -d -p 5557:5557 sensu-watson/freeciv -q 1000 -p 5557 -r /home/freeciv/start-hidden.serv
