#!/bin/bash

RUN mkdir -p sysroot
RUN cp -aR /bin sysroot/bin
RUN cp -aR /lib sysroot/lib
RUN cp -aR /usr sysroot/usr
RUN cp -aR /etc sysroot/etc
RUN cp -aR /var sysroot/var
RUN cp -aR /home sysroot/home
RUN cp -aR /sbin sysroot/sbin
RUN cp -aR /var sysroot/var

#RUN cp -aR /