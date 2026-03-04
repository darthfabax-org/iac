# src/app.py

import json
import logging
from ddtrace import tracer          # DD APM tracing
from datadog_lambda.metric import lambda_metric  # Custom metrics

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Handler real de la Lambda.
    El DD Layer (datadog_lambda.handler.handler) invoca esta función
    después de inicializar el tracer y la extensión.
    """

    # Span personalizado: aparecerá en el APM trace como operación específica
    with tracer.trace("labs.process_event", service="dd-lab-lambda") as span:
        span.set_tag("event.source", event.get("source", "unknown"))
        span.set_tag("env", "labs")
        
        logger.info(json.dumps({
            "message": "Processing event",
            "event_id": context.aws_request_id,
            # NUNCA loguear datos de usuario aquí en prod
        }))
        
        # Métrica custom: aparecerá en DD Metrics Explorer
        # Útil para métricas de negocio (tickets vendidos, pagos procesados)
        lambda_metric(
            "labs.events.processed",
            1,
            tags=["env:labs", "function:dd-lab-lambda"]
        )
        
        return {
            "statusCode": 200,
            "body": json.dumps({"status": "ok"})
        }
