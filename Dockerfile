FROM centos:centos6
RUN yum install -y epel-release
RUN curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
RUN yum install -y nodejs
RUN npm install npm -g
RUN npm install -g coffee-script
ENV HUBOT_ANNOUNCE_ROOMS /william_test_hubot,general
ENV HUBOT_FORECAST_API_KEY 2f1e78e70afa568465b92e1331f9bc31
ENV HUBOT_LOG_LEVEL info
ENV HUBOT_SLACK_TOKEN xoxb-11611029156-6ag4q37YLF4DoCu28nHVKGUA
ENV HUBOT_TRELLO_BOARD UyZAuvjo
ENV HUBOT_TRELLO_KEY d1d531ce05f01cdb8e8e9c411b5e1847
ENV HUBOT_TRELLO_ORGANIZATION vair1
ENV HUBOT_TRELLO_TOKEN fdf0b32eee593ae165c785cc1af0c4b88b0406dff67aeb42f492160d0433c803
ENV HUBOT_WEATHER_CELSIUS true
ENV HUBOT_YELP_CONSUMER_KEY JzgdOryrypRgVxImzLl_7A
ENV HUBOT_YELP_CONSUMER_SECRET g2HSX-m4sWabuVJW9mIf8Idw0y0
ENV HUBOT_YELP_DEFAULT_LOCATION 聯合醫院中興院區
ENV HUBOT_YELP_TOKEN _gWbpcD0rgFTmXT_wlAdkSaQqOse_On9
ENV HUBOT_YELP_TOKEN_SECRET o6RkkCR_8rVRzXsoYkrAl0DR7_0
ENV NODE_ENV=prod
ENV TZ=Asia/Taipei
COPY . vair_robot
WORKDIR vair_robot
VOLUME ["/logs"]
# ENTRYPOINT "bin/hubot -a shell"
CMD ["sh", "bin/hubot", "-a", "slack"]