# OOC Supibot alias

This is a [Supibot](https://github.com/Supinic/supibot) alias written in [ReScript.](https://rescript-lang.org/) 
It's both a pretty usable command and a pretty good example on how to repeat it yourself.

# How to "build"

To get a js file which you can put into a gist, run 

```
  pnpm res:build
  pnpm res:bundle
```

To make it actually work as an alias though, you need to get out all of the contents out of the Immediately Executed Function Expression.

For example, if you have something like this:
```
(() => {
    // node_modules/.pnpm/@rescript+core@1.6.1_rescript@11.1.4/node_modules/@rescript/core/src/Core__Nullable.res.mjs
    ...
})();
```

You just need to remove the beginning and the end like this:

```

    // node_modules/.pnpm/@rescript+core@1.6.1_rescript@11.1.4/node_modules/@rescript/core/src/Core__Nullable.res.mjs
    ...

```

TODO: make a script/executable to do this automatically.

After you get the remainders, you just need to put them into a github gist and then import it in $js in supibot, like in the how to use example below.

# How to use

You just need to create an alias like this:

```
    $alias create ooc js importGist:8d8e76e8c8592964ed03d0058f8d741d errorInfo:true function:"main(args)" ${0+}
```

If you don't plan on modifying the alias, I suggest linking to my version of it to ensure you get the latest updates, like so:

```
    $alias link treuks ooc 
```