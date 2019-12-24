# Client of route search system

https://github.com/hidetaka-f-matsumoto/phoenix_neo4j_example

## Build

```
$ elm make src/App.elm --output src/app.js
$ elm reactor --port=8002
```

See http://localhost:8002
And `elm make --debug` will help your debugging.

## Deploy

Copy bellow files to static site hosting server.

```
src/
└ index.html
└ app.js
└ res/
```
