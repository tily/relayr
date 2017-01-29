FROM ruby:1.9.3
ENV WORKDIR /usr/local/app
ADD . $WORKDIR
WORKDIR $WORKDIR
RUN rm Gemfile.lock
RUN bundle install
