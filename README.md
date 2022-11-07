# *spotDNN*: Provisioning Spot Instances for Predictable Distributed DNN Training in the Cloud

 *spotDNN* is a heterogeneity-aware spot instance provisioning framework to provide predictable performance for DDNN training workloads in the cloud.

## Prototype of *spotDNN*

*spotDNN* comprises four pieces of modules: a parameter profiler, a training performance predictor, a spot instance provisioner and a revocation detector. Users first submit a DDNN training workload, the performance SLOs and the quotas to the *spot*DNN portal. When the parameter profiler finishes the profiling jobs, the performance predictor then predicts the DDNN training time using our performance model. To guarantee the target DDNN training time and training loss, the spot resource provisioner further identifies the cost-efficient resource provisioning plan using spot instances. Once the cost-efficient resource provisioning plan is determined, the instance launcher finally requests the corresponding instances in the plan using the command-line tools (e.g., AWS CLI) and places them in the same VPC. 

![image-20221010114716550](images/prototype.png)

## Modeling DDNN Training Performance in Heterogeneus Environments

We characterize the DDNN training process in a heterogeneous cluster with $j$ normalized iterations and each iteration requires the normalized iteration time $T_{norm}$.  The normalized iteration time $T_{norm}$ can be considered as the expectation of the iteration time of heterogeneous workers, which is formulated as


$$
T_{norm}=\frac{1}{\sum_{i \in \mathcal{N}} \frac{1}{T^i}}
$$


DDNN training loss converges faster as the normalized batch size $b_{norm}$ gets larger, and the convergence rate slows down as more workers $|\mathcal{N}|$are provisioned. Moreover, DDNN training loss is inversely proportional to the normalized iterations $j$. Accordingly, we empirically model the training loss in a heterogeneous cluster as


$$
f_{loss}\left(b_{norm }, \mathcal{N}, j\right)=\frac{\left(\gamma_2 \cdot b_{n o r m}+\gamma_3\right) \sqrt{|\mathcal{N}|}}{j+\gamma_1}+\gamma_4
$$


We proceed to model the normalized batch size $b_{norm}$, which can be defined as the amount of data trained in a cluster per unit time divided by the total number of cluster iterations per unit time. The amount of data trained per unit time in a cluster can be represented as the cluster training speed (i.e., $v$), and the total number of cluster iterations per unit time can be identified as the sum of the iterations per worker per unit time. Accordingly, we formulate the normalized batch size $b_{norm}$ as


$$
b_{norm}=v \cdot T_{norm}
$$


Each iteration of DDNN training can be split into two phases: gradient computation and parameter communication, which are generally processed in sequential for the ASP mechanism. The communication phase consists of the gradient aggregation through PCIe and the parameter communication through the network, which can be formulated as


$$
T_{c o m m}^i=\frac{2 \cdot S_{p a r m}}{B_{w k}^i}+\frac{2 \cdot g^i \cdot S_{\text {parm }}}{B_{p c i e}}
$$


The contention of PS network bandwidth only occurs during part of the communication phase, Accordingly, the available network bandwidth $B_wk^i$ for a worker $i$ as


$$
B_{w k}^i= \begin{cases}P \cdot \frac{B_{p s}}{|\mathcal{N}|}+(1-P) \cdot B_{r e q} & B_{r e q}>\frac{B_{p s}}{|\mathcal{N}|} \mid \\ B_{r e q} & B_{r e q}<\frac{B_{p s}}{|\mathcal{N}|}\end{cases}
$$


The objective is to minimize the monetary cost of provisioned spot instances, while guaranteeing the performance of DDNN training workloads. The optimization problem is formally defined as


$$
\begin{array}{ll}
\min _{\mathcal{N}} & C=T \cdot \sum_{k \in m} n_k \cdot p_k \\
\text { s.t. } & f_{loss}\left(b_{norm}, \mathcal{N}, j\right)=L_{o b j}, \\
& T \leq T_{obj}, \\
& n_k \leq Lim_{k}, \quad \forall k \in m, n_k \in \mathcal{Z}
\end{array}
$$


