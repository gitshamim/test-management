# Base image 
FROM ruby:2.3.1
MAINTAINER jeremy.pumphrey@nih.gov

RUN apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

ENV INSTALL_PATH /usr/app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

ENV RAILS_ENV test

# Install gems 
COPY Gemfile $INSTALL_PATH/
RUN gem install bundler && bundle install && bundle update rake

COPY . . 
RUN ruby -v; rails -v; bundler -v; gem -v
RUN pwd;ls -alt $INSTALL_PATH

#Add a file with build number and date for /version to use
RUN cat $INSTALL_PATH/app/build_number.html

#Insert script to change localhost to docker-compose names
#ADD https://raw.githubusercontent.com/CBIIT/match-docker/master/docker-compose-env.sh .
#RUN chmod 755 docker-compose-env.sh && ls -alt $INSTALL_PATH

# Default command 
#CMD ["rails", "server", "--binding", "0.0.0.0"]
#CMD ./docker-compose-env.sh && rails server
CMD rails server
