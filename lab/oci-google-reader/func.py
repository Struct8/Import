"""
Entry point of the lab function (Dockerfile: `fdk /function/func.py handler`).
The body of the invoke is {"action": "certificate"} or {"action": "test"};
see lab_caller.py.
"""

import io
import json
import traceback

from fdk import response

import lab_caller


def handler(ctx, data: io.BytesIO = None):
    raw = data.getvalue() if data is not None else b""
    try:
        answer = lab_caller.handle(raw)
    except Exception as e:  # the answer is the measurement: report, never fail the invoke
        traceback.print_exc()
        answer = {"error": type(e).__name__, "detail": str(e)[:300]}
    return response.Response(
        ctx,
        response_data=json.dumps(answer, indent=1),
        headers={"Content-Type": "application/json"},
    )
