FROM ruby:2.6.2
ENV LANG C.UTF-8

ARG BUNDLE_GITHUB__COM

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update -qq \
  && apt-get install -y build-essential nginx nodejs yarn \
  && rm -rf /var/lib/apt/lists/*

# Set up dumb-init
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

RUN gem install bundler

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Set up working directory
RUN mkdir /app

# Set up gems
WORKDIR /tmp
ADD .ruby-version .ruby-version
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install -j4

# Finally, add the rest of our app's code
# (this is done at the end so that changes to our app's code
# don't bust Docker's cache)
ADD . /app
WORKDIR /app

# Setup Rails shared folders for Puma / Nginx
RUN mkdir /shared
RUN mkdir /shared/config
RUN mkdir /shared/pids
RUN mkdir /shared/sockets

# Precompile Rails assets
RUN bundle exec rake assets:precompile

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.config"]