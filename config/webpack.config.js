// Example webpack configuration with asset fingerprinting in production.
'use strict'

var path = require('path')
var webpack = require('webpack')
var StatsPlugin = require('stats-webpack-plugin')

// must match config.webpack.dev_server.port
var devServerPort = 3808

// set NODE_ENV=production on the environment to add asset fingerprints
var production = process.env.NODE_ENV === 'production'

var config = {
  entry: {
    // Sources are expected to live in $app_root/webpack
    'artwork-viewer': './webpack/apps/artwork-viewer'
  },

  output: {
    // Build assets directly in to public/webpack/, let webpack know
    // that all webpacked assets start with webpack/

    // must match config.webpack.output_dir
    path: path.join(__dirname, '..', 'public', 'webpack'),
    publicPath: '/webpack/',

    filename: production ? '[name]-[chunkhash].js' : '[name].js'
  },

  module: {
    preLoaders: [
      {
        // set up standard-loader as a preloader
        test: /\.js$/,
        loader: 'standard',
        exclude: /node_modules/
      }
    ],
    loaders: [
      {
        test: /\.js$/,
        loaders: ['babel'],
        exclude: /node_modules/
      },
      {
        test: /\.css$/,
        loader: 'style-loader!css-loader',
        exclude: /node_modules/
      }
    ]
  },

  resolve: {
    root: path.join(__dirname, '..', 'webpack'),
    alias: {
      components: path.resolve(__dirname, '..', 'webpack', 'components')
    }
  },

  plugins: [
    // must match config.webpack.manifest_filename
    new StatsPlugin('manifest.json', {
      // We only need assetsByChunkName
      chunkModules: false,
      source: false,
      chunks: false,
      modules: false,
      assets: true
    })]
}

if (production) {
  config.plugins.push(
    new webpack.NoErrorsPlugin(),
    new webpack.optimize.UglifyJsPlugin({
      compressor: { warnings: false },
      sourceMap: false
    }),
    new webpack.DefinePlugin({
      'process.env': { NODE_ENV: JSON.stringify('production') }
    }),
    new webpack.optimize.DedupePlugin(),
    new webpack.optimize.OccurenceOrderPlugin()
  )
} else {
  config.devServer = {
    port: devServerPort,
    headers: { 'Access-Control-Allow-Origin': '*' }
  }
  config.output.publicPath = '//localhost:' + devServerPort + '/webpack/'
  // Source maps
  config.devtool = 'cheap-module-eval-source-map'
}

module.exports = config