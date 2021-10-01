FROM kong:2.3.0 as builder

USER root

RUN apk add --no-cache git zip libxml2 gcc && \
    git config --global url.https://github.com/.insteadOf git://github.com/

COPY . /plugins/soap4kong

WORKDIR /plugins/soap4kong/

ENV LUAROCKS_SOAP4KONG=kong-plugin-soap4kong
ENV LUAROCKS_SOAP4KONG_VERSION=0.1.0-1

RUN luarocks make kong-plugin-soap4kong-0.1.0-1.rockspec && \
    luarocks pack ${LUAROCKS_SOAP4KONG} ${LUAROCKS_SOAP4KONG_VERSION}

ENV LUAROCKS_SOAP4KONG_GENERATOR=kong-plugin-soap4kong-generator
ENV LUAROCKS_SOAP4KONG_GENERATOR_VERSION=0.1.0-1

RUN luarocks make kong-plugin-soap4kong-generator-0.1.0-1.rockspec && \
    luarocks pack ${LUAROCKS_SOAP4KONG_GENERATOR} ${LUAROCKS_SOAP4KONG_GENERATOR_VERSION}

FROM kong:2.3.0

# Enable plugins
ENV KONG_PLUGINS="bundled,soap4kong,soap4kong-generator"
ENV JWT_KEYCLOAK_PRIORITY="900"

COPY --from=builder /plugins/soap4kong/*.rock /tmp/plugins/

USER root

# Install plugins
RUN luarocks install /tmp/plugins/kong-plugin-soap4kong*.rock
RUN luarocks install /tmp/plugins/kong-plugin-soap4kong-generator*.rock