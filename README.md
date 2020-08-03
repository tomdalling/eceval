Eceval
======

**E**mbedded **c**ode **eval**uator. A command-line tool that evaluates Ruby
code embedded in markdown, and outputs the markdown with the results of
evaluation merged in to it.

:warning: DANGER :warning:
--------------------------

**NEVER RUN THIS WITH UNTRUSTED INPUT**. This gem does arbitrary code execution,
by design. To put it another way, this is a hacker's dream, and a security
nightmare. Never run this on any markdown document unless you are 100% sure that
the document is safe.


But Why Tho?
------------

Eceval can be used to augment `README.md` files with the real results of running
the code examples. It ensures that the examples run correctly, and show correct
output.

For example, if you ran `eceval README.md` on this file, it would output the
whole markdown file, but this following code block ...

```ruby
1 + 1 #=>
6 / 0 #=> !!!
```

... would be augmented to be the same as this code block:

```ruby
1 + 1 #=> 2
6 / 0 #=> !!! ZeroDivisionError: divided by 0
```

Usage
-----

Install the `eceval` gem using Bundler or just `gem install eceval`.

Then run the `eceval` binary to see the help documentation:

```bash
eceval --help
```

Contributing
------------

Open PRs and issues on GitHub.

It would be cool to get this working for other languages, but right now it's
hard-coded for Ruby.

Sandboxing would be good too, but I don't know how feasible it is.


License
-------

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

