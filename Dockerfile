FROM ncbi/sra-tools

 RUN apk add --update \
 python \
 curl \
 which \
 bash

 RUN curl -sSL https://sdk.cloud.google.com | bash

 ENV PATH $PATH:/root/google-cloud-sdk/bin

# Add your additional instructions here

RUN cp /root/.ncbi/user-settings.mkfg $HOME/.ncbi

CMD ["/bin/bash"]