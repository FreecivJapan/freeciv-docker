sudo docker run -v /home/vagrant/5556/docker-home:/home/freeciv -v /home/vagrant/5556/rulesets:/usr/local/share/freeciv/ --rm -it --name test-container -d -p 5556:5556 test-image
