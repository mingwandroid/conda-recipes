typedef struct _igraph_interruption_handler_t
{
	int a;
} igraph_interruption_handler_t;

extern IGRAPH_THREAD_LOCAL igraph_interruption_handler_t 
  *igraph_i_interruption_handler;

