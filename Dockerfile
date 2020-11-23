FROM alpine:3.12

RUN apk add git jq bash curl

COPY --from=golang:1.13-alpine /usr/local/go/ /usr/local/go/

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN go get github.com/google/go-jsonnet/cmd/jsonnet


WORKDIR /usr/src/app
RUN git clone https://github.com/ridebeam/grafonnet-lib
COPY alerts ./alerts
COPY dashboards ./dashboards
COPY update.sh .



# FROM bitnami/git as builder

# WORKDIR /usr/src/app
# RUN git clone https://github.com/ridebeam/grafonnet-lib

# FROM python

# # RUN pip3 install wheel
# RUN pip install jsonnet
# WORKDIR /usr/src/app
# COPY --from=builder /usr/src/app .
# COPY alerts ./alerts
# COPY dashboards ./dashboards
COPY update.sh .

# # RUN chmod 777 update.sh

# CMD ["bash", "update.sh"]