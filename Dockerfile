# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=2.6.9
FROM ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Update gems and bundler
RUN gem update --system 3.4.22 --no-document && \
    gem install -N bundler

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 sqlite3 chromium fonts-liberation && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Reports are printed to PDF by headless Chrome, which renders the same
# Highcharts markup the browser page does. Reports::PdfRenderer reads this.
ENV CHROME_BIN="/usr/bin/chromium"

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production" 


# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libffi-dev libyaml-dev node-gyp pkg-config python && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install JavaScript dependencies
ARG NODE_VERSION=24.18.0
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -fsSL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@"${YARN_VERSION}" && \
    rm -rf /tmp/node-build-master

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
RUN ls node_modules/@babel/plugin-proposal-private-methods


# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN NODE_OPTIONS=--openssl-legacy-provider \
    SECRET_KEY_BASE=DUMMY \
    ./bin/rails assets:precompile


# Final stage for app image
FROM base


# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir /data && \
    chown -R 1000:1000 db log storage tmp /data
USER 1000:1000

# Deployment options
ENV DATABASE_URL="sqlite3:///data/production.sqlite3" \
    RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
VOLUME /data
CMD ["./bin/rails", "server"]
