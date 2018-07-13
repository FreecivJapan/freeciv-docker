# freecivを動かすdockerファイルとその補助ファイル群です

## 使用前に
docker-homeのパーミッションを777に変更すること。


## ビルド方法
$ sudo docker build -t sensu-watson/freeciv .

## 起動方法
$ sudo docker run -v /home/vagrant/5556/docker-home:/home/freeciv -v /home/vagrant/5556/rulesets:/usr/local/share/freeciv/ --rm -it --name freeciv5556 -d -p 5556:5556 sensu-watson/freeciv

