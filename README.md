# overature
[![Build Status](https://travis-ci.org/kurtis-s/overature.svg?branch=master)](https://travis-ci.org/kurtis-s/overature)
[![Coverage status](https://codecov.io/gh/kurtis-s/overature/branch/master/graph/badge.svg)](https://codecov.io/github/kurtis-s/overature?branch=master)

`overature` makes writing Markov chain Monte Carlo (MCMC) samplers simpler.  With overature you can:

* **Write less code** `overature` eliminates boilerplate code, looping through sampling functions and saving the results automatically.
* **Easily recover from interruptions** Samples can be saved on-disk as the MCMC runs, so it's easy to resume an MCMC if something goes wrong.
* **Run more chains in parallel** Saving samples on-disk results in a dramatically smaller memory footprint for high-dimensional models, allowing more chains to be run when available RAM is limited.
* **Monitor chain progress** Samples can be viewed in another R process while the MCMC is still running.

## Usage
### Basic Usage
Using `overature` is easy:
#### 1. Write the sampling functions
```r
SampleX <- function(x) {
    x + 1
}

SampleY <- function(y) {
    y * y
}
```
#### 2.  Initialize the MCMC
```r
mcmc <- InitMcmc(3) # Run the chain for 3 iterations
```
#### 3.  Set initial values for the chain
```r
x <- c(0, 10) # Initial value for x
y <- 2 # Initial value for y
```
#### 4.  Run the MCMC
```r
samples <- mcmc({
    x <- SampleX(x)
    y <- SampleY(y)
})
```
#### 5.  Analyze the results
```r
> samples$x
     [,1] [,2]
[1,]    1   11
[2,]    2   12
[3,]    3   13
> samples$y
     [,1]
[1,]    4
[2,]   16
[3,]  256
```
### Save samples on-disk
To save samples on disk, specify the directory where the samples should be saved:
```r
mcmc <- InitMcmc(3, backing.path=/save/directory/path/)
samples <- mcmc({
    x <- SampleX(x)
    y <- SampleY(y)
})
```
The samples can be analyzed as before:
```r
> samples$x[,]
     [,1] [,2]
[1,]    1   11
[2,]    2   12
[3,]    3   13
> samples$y[,, drop=FALSE]
     [,1]
[1,]    4
[2,]   16
[3,]  256
```

To load the samples from disk, use `LoadMcmc`:
```r
loaded.samples <- LoadMcmc(/save/directory/path/)
```

To convert a file-backed MCMC into a list of R in-memory matrices, use `ToMemory`:
```r
in.memory.samples <- ToMemory(loaded.samples)
> in.memory.samples
$x
     [,1] [,2]
[1,]    1   11
[2,]    2   12
[3,]    3   13

$y
     [,1]
[1,]    4
[2,]   16
[3,]  256
```

### Monitor the progress of an MCMC while it's still running
Samples from an MCMC can be viewed before its completion.  First, start the slow running MCMC as a file-backed chain:
```r
slow.mcmc <- InitMcmc(10000, backing.path=/save/directory/path/)
slow.mcmc({
    x <- SlowSampler()
})
```

Then, in another R process while the MCMC is still running, use `Peek` to load and analyze the samples taken so far:
```r
samples.so.far <- Peek(/save/directory/path/)
samples.so.far$x[,]
```

### Get more information
More examples and details are given in the package documentation.

## Installation
After installing [devtools](https://github.com/r-lib/devtools) run:
```r
library(devtools)
install_github("kurtis-s/overature")
```
