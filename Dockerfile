FROM centos:centos6
ENV HUBOT_ANNOUNCE_ROOMS /william_test_hubot,general
ENV HUBOT_FORECAST_API_KEY /2f1e78e70afa568465b92e1331f9bc31
ENV HUBOT_LOG_LEVEL /info
ENV HUBOT_SLACK_TOKEN /xoxb-15818470115-cDbCUqPIXRKOowylhnA928Fa
ENV HUBOT_TRELLO_BOARD /UyZAuvjo
ENV HUBOT_TRELLO_KEY /d1d531ce05f01cdb8e8e9c411b5e1847
ENV HUBOT_TRELLO_ORGANIZATION /vair1
ENV HUBOT_TRELLO_TOKEN /fdf0b32eee593ae165c785cc1af0c4b88b0406dff67aeb42f492160d0433c803
ENV HUBOT_WEATHER_CELSIUS /true
ENV HUBOT_YELP_CONSUMER_KEY /JzgdOryrypRgVxImzLl_7A
ENV HUBOT_YELP_CONSUMER_SECRET /g2HSX-m4sWabuVJW9mIf8Idw0y0
ENV HUBOT_YELP_DEFAULT_LOCATION /聯合醫院中興院區
ENV HUBOT_YELP_TOKEN /_gWbpcD0rgFTmXT_wlAdkSaQqOse_On9
ENV HUBOT_YELP_TOKEN_SECRET /o6RkkCR_8rVRzXsoYkrAl0DR7_0
ENV NODE_ENV=local
ENV TZ=Asia/Taipei
RUN yum install -y epel-release
RUN yum install -y nodejs npm
RUN npm install -g yo generator-hubot coffee-script
RUN useradd -ms /bin/bash william
WORKDIR /home/william
COPY . vair_robot
COPY ./run_file .
RUN chown -R william:william /home/william 
USER william
RUN cd vair_robot; npm install
WORKDIR vair_robot
CMD ./bin/hubot --adapter slack