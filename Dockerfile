FROM ruby:2.6.2
ENV LANG C.UTF-8

# Enable bundling of private gems
ARG BUNDLE_GITHUB__COM

# Add package sources
RUN   curl -sL https://deb.nodesource.com/setup_8.x | bash - \
   && curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
   && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
   && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
   && echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list

# Install packages
RUN apt-get update -qq && apt-get install -y \
    google-chrome-stable \
    # libgconf-2-4 \
    # libnss3 \
    nodejs \
    postgresql-client \
    yarn \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Disable Chrome sandbox
RUN sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' "/opt/google/chrome/google-chrome"

# Set up dumb-init
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

RUN gem install bundler

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Set up working directory
RUN mkdir -p /app/rosalind

# Set up gems
WORKDIR /tmp
ADD .ruby-version .ruby-version
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install -j4

# Install node modules into a directory outside of the project dir,
# so that they can be cached
WORKDIR /app
ADD package.json package.json
ADD yarn.lock yarn.lock
RUN yarn install

# Finally, add the rest of our app's code
# (this is done at the end so that changes to our app's code
# don't bust Docker's cache)
ADD . /app/rosalind
WORKDIR /app/rosalind

# Setup Rails shared folders for Puma / Nginx
RUN mkdir /shared
RUN mkdir /shared/config
RUN mkdir /shared/pids
RUN mkdir /shared/sockets

# Precompile Rails assets
RUN bundle exec rake assets:precompile

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.config"]