@echo off

set HUBOT_ANNOUNCE_ROOMS=william_test_hubot,general
set HUBOT_FORECAST_API_KEY=forcast api key
set HUBOT_LOG_LEVEL=info
set HUBOT_SLACK_TOKEN="slack token"
set HUBOT_TRELLO_BOARD="trello board"
set HUBOT_TRELLO_KEY="trello key"
set HUBOT_TRELLO_ORGANIZATION="trello organization"
set HUBOT_TRELLO_TOKEN="trello token"
set HUBOT_WEATHER_CELSIUS=true
set HUBOT_YELP_CONSUMER_KEY="yelp consumer key"
set HUBOT_YELP_CONSUMER_SECRET="yelp consumer secret"
set HUBOT_YELP_DEFAULT_LOCATION=聯合醫院中興院區
set HUBOT_YELP_TOKEN="yelp token"
set HUBOT_YELP_TOKEN_SECRET="yelp secret"
set NODE_ENV=prod
set TZ=Asia/Taipei

node_modules\.bin\hubot.cmd --name "pal" %*