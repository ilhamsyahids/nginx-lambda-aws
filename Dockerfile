FROM public.ecr.aws/apparentorder/reweb as reweb

FROM php:8.1.9-fpm-bullseye
COPY --from=reweb /reweb /reweb

# setup the local lambda runtime (to run the image locally)
RUN curl -L -o /usr/bin/lambda_rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/download/v1.2/aws-lambda-rie-x86_64
RUN chmod +x /usr/bin/lambda_rie

# install dependencies
RUN apt-get update
# zip is used for installing composer dependencies
RUN apt-get install -y zip nginx git
RUN useradd -r nginx

###############################################################
########## start of custom tweaks - NGINX specific ############ 
###############################################################

# make nginx listin on 9186
# RUN sed -i "s/listen       80/listen       9186/g" /etc/nginx/conf.d/default.conf

# move the nginx pid file to a directory that can be written 
# RUN sed -i "s,pid        /var/run/nginx.pid;,pid        /tmp/nginx.pid;,g" /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# put the nginx logs to stdout and stderr (which also avoids writing to non writable folders)
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# redirect all cache files to /tmp (writable)
COPY cachepaths.conf /etc/nginx/conf.d/cachepaths.conf

###############################################################
########### end of custom tweaks - NGINX specific ############# 
###############################################################

# COPY index.html /usr/share/nginx/html/index.html
COPY index.php /usr/share/nginx/html/index.php

# reweb environment variables
ENV REWEB_APPLICATION_EXEC nginx && php-fpm
ENV REWEB_APPLICATION_PORT 9186
ENV REWEB_WAIT_CODE 200

ENTRYPOINT ["/reweb"]
