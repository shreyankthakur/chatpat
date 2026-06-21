FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN python manage.py collectstatic --noinput

EXPOSE 8000

RUN echo '#!/bin/sh' > /start.sh && \
    echo 'python manage.py migrate --noinput' >> /start.sh && \
    echo "daphne -b 0.0.0.0 -p \${PORT:-8000} core.asgi:application" >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]