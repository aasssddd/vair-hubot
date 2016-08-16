FROM centos:centos6
RUN yum install -y epel-release
RUN curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
RUN yum install -y nodejs
RUN npm install npm -g
RUN npm install -g coffee-script
ENV HUBOT_ANNOUNCE_ROOMS /william_test_hubot,general
ENV HUBOT_FORECAST_API_KEY "forcast api key"
ENV HUBOT_LOG_LEVEL info
ENV HUBOT_SLACK_TOKEN "slack token"
ENV HUBOT_TRELLO_BOARD "trello board"
ENV HUBOT_TRELLO_KEY "trello key"
ENV HUBOT_TRELLO_ORGANIZATION "trello organization"
ENV HUBOT_TRELLO_TOKEN "trello token"
ENV HUBOT_WEATHER_CELSIUS true
ENV HUBOT_YELP_CONSUMER_KEY "yelp consumer key"
ENV HUBOT_YELP_CONSUMER_SECRET "yelp consumer secret"
ENV HUBOT_YELP_DEFAULT_LOCATION 聯合醫院中興院區
ENV HUBOT_YELP_TOKEN "yelp token"
ENV HUBOT_YELP_TOKEN_SECRET "yelp token secret"
ENV NODE_ENV=prod
ENV TZ=Asia/Taipei
COPY . vair_robot
WORKDIR vair_robot
VOLUME ["/logs"]
# ENTRYPOINT "bin/hubot -a shell"
CMD ["sh", "bin/hubot", "-a", "slack"]