# Sample from N(1, 2^2) ---------------------------------------------------
LogP <- function(x) dnorm(x, 1, 2, log=TRUE) # Target distribution

f <- function(x, s) { # Non-adaptive Metropolis sampler
    x.prop <- x + rnorm(1, 0, s)
    if(AcceptProp(LogP(x), LogP(x.prop))) {
        x <- x.prop
    }

    return(x)
}

s.start <- 0.1
g <- Amwg(f, s.start, batch.size=25)

n.save <- 10000
Mcmc <- InitMcmc(n.save)
y <- 0
x <- 0
samples <- Mcmc({
    y <- f(y, s.start) # Non-adaptive
    x <- g(x) # Adaptive
})

plot(1:n.save, samples$x, ylim=c(-10, 10), main="Traceplots", xlab="Iteration",
     ylab="Value", type='l')
lines(1:n.save, samples$y, col="red")
legend("bottomleft", legend=c("Adaptive", "Non-adaptive"),
       col=c("black", "red"), lty=1, cex=0.8)

# Sample from Gamma(10, 5) ------------------------------------------------
LogP <- function(x) dgamma(x, 10, 5, log=TRUE) # Target distribution

f <- function(x, s) { # Non-adaptive Metropolis sampler
    x.prop <- x + rnorm(1, 0, s)
    if(AcceptProp(LogP(x), LogP(x.prop))) {
        x <- x.prop
    }

    return(x)
}

s.start <- 10
stop.after <- 5000 # Stop changing the proposal SD after 5000 iterations
g <- Amwg(f, s.start, batch.size=25, stop.after=stop.after)

n.save <- 10000
Mcmc <- InitMcmc(n.save)
x <- 1
samples <- Mcmc({
    x <- g(x)
})
hist(samples$x[stop.after:n.save,], xlab="x", main="Gamma(10, 5)", freq=FALSE)
curve(dgamma(x, 10, 5), from=0, to=max(samples$x), add=TRUE, col="blue")

# Overdispersed Poisson ---------------------------------------------------
## Likelihood:
## y_i|theta_i ~ Pois(theta_i), i=1,...,n
## Prior:
## theta_i ~ Log-Normal(mu, sigma^2)
## mu ~ Normal(m, v^2), m and v^2 fixed
## sigma^2 ~ InverseGamma(a, b), a and b fixed

\donttest{
SampleSigma2 <- function(theta.vec, mu, a, b, n.obs) {
    1/rgamma(1, a + n.obs/2, b + (1/2)*sum((log(theta.vec) - mu)^2))
}

SampleMu <- function(theta.vec, sigma.2, m, v.2, n.obs) {
    mu.var <- (1/v.2 + n.obs/sigma.2)^(-1)
    mu.mean <- (m/v.2 + sum(log(theta.vec))/sigma.2) * mu.var

    return(rnorm(1, mu.mean, sqrt(mu.var)))
}

LogDTheta <- function(theta, mu, sigma.2, y) {
    dlnorm(theta, mu, sqrt(sigma.2), log=TRUE) + dpois(y, theta, log=TRUE)
}

# Non-adaptive Metropolis sampler
SampleTheta <- function(theta.vec, mu, sigma.2, y.vec, n.obs, s) {
    theta.prop <- exp(log(theta.vec) + rnorm(n.obs, 0, s))

    # Jacobians, because proposals are made on the log scale
    j.curr <- log(theta.vec)
    j.prop <- log(theta.prop)

    log.curr <- LogDTheta(theta.vec, mu, sigma.2, y.vec) + j.curr
    log.prop <- LogDTheta(theta.prop, mu, sigma.2, y.vec) + j.prop
    theta.vec <- ifelse(AcceptProp(log.curr, log.prop), theta.prop, theta.vec)

    return(theta.vec)
}

## Data
y.vec <- warpbreaks$breaks
n.obs <- length(y.vec)

## Setup adaptive Metropolis sampler
s <- rep(1, n.obs)
# s is a vector, so the acceptance rate of each component will be tracked
# individually in the adaptive Metropolis sampler
SampleThetaAdapative <- Amwg(SampleTheta, s)

## Set prior
v.2 <- 0.05
m <- log(30) - v.2/2
a <- 1
b <- 2

## Initialize parameters
theta.vec <- y.vec
mu <- m

## MCMC
Mcmc <- InitMcmc(10000)
samples <- Mcmc({
    sigma.2 <- SampleSigma2(theta.vec, mu, a, b, n.obs)
    mu <- SampleMu(theta.vec, sigma.2, m, v.2, n.obs)
    theta.vec <- SampleThetaAdapative(theta.vec, mu, sigma.2, y.vec, n.obs)
})
}
