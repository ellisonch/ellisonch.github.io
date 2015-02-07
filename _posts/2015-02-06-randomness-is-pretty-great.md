---
layout: post
title: Randomness Is Pretty Great
custom_js:
# - shuffle
---
Let's say you're tasked with trying to find a needle in a haystack.
There's some number (or a few numbers) with a specific property, and you're trying to find one of those numbers.
You already have a boolean function that encodes the property---give it a number, and it returns true iff the number has the property.

Depending on the size of the state space and the speed of your function, you're probably going to want to parallelize and distribute this task across multiple cores or even machines.

## Options

One way to approach this problem is to build a lot of infrastructure.
To get the most out of your hardware, you'll need to make sure the different instances don't duplicate work.
If the problem takes long enough, you'll probably have instances that die and need to be restarted.
You'll have to consider how to add and remove instances dynamically, in case you buy new hardware.
You'll need ways to suspend and resume operation in case you want to upgrade code in running instances.
In all these cases you'll have the burden of keeping track of where that instance left off, starting it back in the right place, and making sure no other instances are searching the same part of the state space.
You'll need to make sure the instances don't run out of work, even if they're on heterogeneous hardware.
On top of all that, you better make sure your solution is correct---how bad would it be if you spent hundreds of years of computation time but skipped over the solution because of a bug?
Whew.
What a headache.

Another option is to leave everything up to chance.
Each instance will simply generate random numbers to work on, and run the function on those numbers.
The bulk of the code becomes:
{% highlight c %}
while (true) {
	int r = rand();
	if (f(r) {
		success(r);
		break;
	}
}
{% endhighlight %}
No worrying about duplication of work, even on an individual instance.
No headaches!
But surely this can't be efficient.
As times goes on, the majority of the instances will be hitting more and more collisions, that is, they will be duplicating work that's already been done somewhere else.
Because of the randomness and the collisions, the amount of extra work must be some crazy factorial or exponential burden, right?

## Analysis

Let's assume there's \\(m\\) needles in a haystack of size \\(n\\) distributed randomly from a uniform distribution.
If you search through the space with no duplication of work, the expected number of values you'd have to try before finding a match is:

$$E_{\text{linear}} = \frac{n+1}{m+1}$$

It's not super easy to see why this is the case, but thankfully someone else has already done the calculation.[^1]
Because there's no duplication, this is really the best you can hope to do, so the linear search represents "efficient work".

[^1]: See, e.g., [here](http://arxiv.org/abs/1404.1161), Thm. 2.5.

For a random algorithm (that is, with duplication), the expected number of choices should satisfy this:

$$E_{\text{rand}} = 1 \cdot \frac{m}{n} + (E_{\text{rand}} + 1) \cdot \frac{n - m}{n}$$

Said another way, you have a \\(\frac{m}{n}\\) chance of choosing a needle in one go, and you have \\(\frac{n-m}{n}\\) chance of choosing the needle in \\(E_{\text{rand}} + 1\\) choices (the \\(+1\\) is from failing this time).
Following the algebra, this works out to be:

$$E_{\text{rand}} = \frac{n}{m}$$

These expected values don't look very different!
Let's work out how different they are.
The work done in random search as a proportion of efficient work (called \\(\text{PW}\\), or proportional work) amounts to:

$$\text{PW} = \frac{E_{\text{rand}}}{E_{\text{linear}}} = \frac{\frac{n}{m}}{\frac{n+1}{m+1}} = \frac{nm + n}{nm + m}$$

So, for a set of size 100, when there's a single needle, the proportional work done is \\(\frac{1 \cdot 100 + 100}{1 \cdot 100 + 1} \approx 1.98\\), or just under twice as much work.
In fact, it's easy to see that \\(\text{PW}\\) is never more than 2, since:

<!-- 
$$
\begin{align*}
\frac{n}{n+2} &\lt m && \text{since $m \ge 1$}\\
n &\lt nm + 2m \\
nm + n &\lt 2nm + 2m \\
\frac{nm + n}{nm + m} &\lt 2 \\
\end{align*}
$$
 -->

$$
\begin{align*}
PW &= \frac{nm + n}{nm + m} \\
 &= \frac{(m + 1)n}{m(n + 1)} \\
&= \frac{m + 1}{m} \cdot \frac{n}{n+1} \\
&< \frac{m + 1}{m} && \text{since $\frac{n}{n+1} < 1$}\\
&< 2 && \text{when $m = 1$}
\end{align*}
$$

This means no matter what, on average, the random strategy will do less than twice the work of the linear search.
The \\(\frac{m+1}{m}\\) (or \\(1 + \frac{1}{m}\\)) bound is even tighter.
This bound means the amount of extra work is always less than \\(\frac{1}{m}\\).

This is a really neat result, because you'll never do more than twice the necessary work (in the average case), and having more needles shrinks the overhead very quickly!
My vote is to throw twice the hardware at the problem, and take an early day.



Thanks to [David Lazar](https://davidlazar.org/) for the initial idea, and [Tom Jacques](https://github.com/tejacques) and [Jeff Jones](https://github.com/jeffljones) for helpful contributions.
