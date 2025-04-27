FROM ruby:3.4.3

RUN apt-get update -y ; apt-get upgrade -y openssl 
RUN apt-get install -y unrar-free build-essential libpq-dev cmake vim poppler-utils postgresql-client

RUN useradd -c 'restme' -m -d /home/restme -s /bin/bash restme

ENV DISPLAY=:99
ENV RUBY_GC_MALLOC_LIMIT=90000000
ENV RUBY_GC_HEAP_FREE_SLOTS=200000
ENV APP_HOME=/var/www/restme

RUN mkdir -p $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/

RUN chown -R $(whoami):$(whoami) $APP_HOME

RUN gem install bundler \
    && bundle install --jobs 3

ADD . $APP_HOME

EXPOSE 3000

CMD ["./bin/rails", "server"]
