FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY chat/ /app/chat/
COPY . .
RUN python manage.py collectstatic --noinput
EXPOSE 8000
CMD ["python", "start.py"]