@echo off

set HUBOT_ANNOUNCE_ROOMS=william_test_hubot,general
set HUBOT_FORECAST_API_KEY=2f1e78e70afa568465b92e1331f9bc31
set HUBOT_LOG_LEVEL=debug
set HUBOT_SLACK_TOKEN=xoxb-11611029156-6ag4q37YLF4DoCu28nHVKGUA
set HUBOT_TRELLO_BOARD=UyZAuvjo
set HUBOT_TRELLO_KEY=d1d531ce05f01cdb8e8e9c411b5e1847
set HUBOT_TRELLO_ORGANIZATION=vair1
set HUBOT_TRELLO_TOKEN=fdf0b32eee593ae165c785cc1af0c4b88b0406dff67aeb42f492160d0433c803
set HUBOT_WEATHER_CELSIUS=true
set HUBOT_YELP_CONSUMER_KEY=JzgdOryrypRgVxImzLl_7A
set HUBOT_YELP_CONSUMER_SECRET=g2HSX-m4sWabuVJW9mIf8Idw0y0
rem set HUBOT_YELP_SEARCH_ADDRESS=No.139, Zhengzhou Road Datong Dist., Taipei
rem set HUBOT_YELP_SEARCH_RADIUS=1000
rem set HUBOT_YELP_SORT=0
set HUBOT_YELP_DEFAULT_LOCATION=No.139, Zhengzhou Road Datong Dist., Taipei
set HUBOT_YELP_TOKEN=_gWbpcD0rgFTmXT_wlAdkSaQqOse_On9
set HUBOT_YELP_TOKEN_SECRET=o6RkkCR_8rVRzXsoYkrAl0DR7_0
set NODE_ENV=prod
set HUBOT_HANGUPS_PYTHON=python

npm install && node_modules\.bin\hubot.cmd --name "pal" %* 