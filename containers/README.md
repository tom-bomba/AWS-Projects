The webserver is shared between the two stages.

Stage 1 - ECS

Stage 2 - EKS

NOTE: Container refs DB creds from environ variables. Swap to secrets or other more secure alternative in a shared/non-test environ.


Stage 3 - EKS. Added Redis for sessions, added secrets for DB creds, templated more variables.
