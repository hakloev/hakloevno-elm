const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');

console.log('Environment:', process.env.NODE_ENV);

let commonPlugins = [
    new HtmlWebpackPlugin({
      template: './static/index.html',
    }),
]

commonPlugins = process.env.NODE_ENV === 'development' ? commonPlugins : commonPlugins.concat([
    new webpack.optimize.UglifyJsPlugin({
        compress: {
            warnings: false,
        }
    }),
])

let commonConfig = {
  entry: [path.join(__dirname, './src/index.js')],

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].js'
  },

  resolve: {
    extensions: ['.js', '.elm'],
  },

  plugins: commonPlugins,

  module: {
    noParse: /\.elm$/,
    rules: [
      // {
      //   test: /\.html$/,
      //   exclude: /node_modules/,
      //   loader: 'file-loader?name=[name].[ext]'
      // },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: process.env.NODE_ENV === 'development' ? 'elm-hot-loader!elm-webpack-loader?verbose=true&warn=true&debug=true' : 'elm-webpack-loader',
      },
      {
         test: /\.(css|scss)$/,
         loaders: [
           'style-loader', 'css-loader', 'sass-loader',
         ]
      },
    ],
  },

  devServer: {
    inline: true,
    historyApiFallback: true,
    stats: { colors: true },
    contentBase: './src',
    proxy: {
        '/api': {
            target: 'http://localhost:8000',
            secure: false,
        },
    },
  },

};

module.exports = commonConfig;
