import numpy as np
S = 1.7/1.9
def T(p):  # coordenadas do modelo original -> Godot (pés em y=0, olha para -Z, 1.7 m)
    p=np.asarray(p,float)
    return np.stack([-p[...,0]*S,(p[...,1]+0.95)*S,-p[...,2]*S],-1)

# (nome, pai, posição da junta em coords do modelo original)
JOINTS=[
 ('hips',None,(0,-0.03,0)),('spine','hips',(0,0.10,0)),('chest','spine',(0,0.32,0)),('head','chest',(0,0.58,0)),
 ('upperarm_L','chest',(0.19,0.47,0)),('forearm_L','upperarm_L',(0.27,0.26,0)),('hand_L','forearm_L',(0.30,0.05,0)),
 ('upperarm_R','chest',(-0.19,0.47,0)),('forearm_R','upperarm_R',(-0.27,0.26,0)),('hand_R','forearm_R',(-0.30,0.05,0)),
 ('thigh_L','hips',(0.09,-0.06,0)),('shin_L','thigh_L',(0.10,-0.50,0)),('foot_L','shin_L',(0.11,-0.84,0)),
 ('thigh_R','hips',(-0.09,-0.06,0)),('shin_R','thigh_R',(-0.10,-0.50,0)),('foot_R','shin_R',(-0.11,-0.84,0)),
]
NAMES=[j[0] for j in JOINTS]
PARENT=[None if j[1] is None else NAMES.index(j[1]) for j in JOINTS]
REST_WORLD=T(np.array([j[2] for j in JOINTS]))      # (16,3)
REST_LOCAL=REST_WORLD.copy()
for i,p in enumerate(PARENT):
    if p is not None: REST_LOCAL[i]=REST_WORLD[i]-REST_WORLD[p]

# segmentos de influência: (osso, ponto a, ponto b, raio) em coords do modelo
SEGS=[
 ('hips',(0,-0.03,0),(0,0.10,0),0.24),('spine',(0,0.10,0),(0,0.32,0),0.26),('chest',(0,0.32,0),(0,0.55,0),0.30),
 ('head',(0,0.58,0),(0,0.90,0),0.20),
 ('upperarm_L',(0.19,0.47,0),(0.27,0.26,0),0.095),('forearm_L',(0.27,0.26,0),(0.30,0.05,0),0.08),('hand_L',(0.30,0.05,0),(0.30,-0.06,0),0.08),
 ('upperarm_R',(-0.19,0.47,0),(-0.27,0.26,0),0.095),('forearm_R',(-0.27,0.26,0),(-0.30,0.05,0),0.08),('hand_R',(-0.30,0.05,0),(-0.30,-0.06,0),0.08),
 ('thigh_L',(0.09,-0.06,0),(0.10,-0.50,0),0.15),('shin_L',(0.10,-0.50,0),(0.11,-0.84,0),0.12),('foot_L',(0.11,-0.84,0),(0.11,-0.93,0.2),0.13),
 ('thigh_R',(-0.09,-0.06,0),(-0.10,-0.50,0),0.15),('shin_R',(-0.10,-0.50,0),(-0.11,-0.84,0),0.12),('foot_R',(-0.11,-0.84,0),(-0.11,-0.93,0.2),0.13),
]
def seg_dist(P,a,b):
    a=np.asarray(a,float); b=np.asarray(b,float); ab=b-a
    t=np.clip(((P-a)@ab)/(ab@ab),0,1)
    return np.linalg.norm(P-(a+t[:,None]*ab),axis=1)

def weights(P, force=None):
    """P em coords do modelo original. Retorna (N,4) índices e pesos."""
    N=len(P); W=np.zeros((N,len(NAMES))); D=np.zeros((N,len(NAMES)))
    for name,a,b,R in SEGS:
        k=NAMES.index(name); d=seg_dist(P,a,b); D[:,k]=d
        W[:,k]=np.clip(1-d/R,0,1)**2
        if name.startswith('upperarm'):
            W[:,k]*=np.clip((np.abs(P[:,0])-0.14)/0.06,0,1)
    none=W.sum(1)==0
    W[none,np.argmin(D[none],1)]=1.0
    if force is not None:
        for bone,mask in force:
            W[mask]=0; W[mask,NAMES.index(bone)]=1.0
    top=np.argsort(-W,1)[:,:4]
    w=np.take_along_axis(W,top,1); w/=w.sum(1,keepdims=True)
    return top.astype(np.uint8), w.astype(np.float32)

# ---- quaternions (x,y,z,w) ----
def qmul(a,b):
    x1,y1,z1,w1=a; x2,y2,z2,w2=b
    return np.array([w1*x2+x1*w2+y1*z2-z1*y2, w1*y2-x1*z2+y1*w2+z1*x2, w1*z2+x1*y2-y1*x2+z1*w2, w1*w2-x1*x2-y1*y2-z1*z2])
def qaxis(ax,deg):
    r=np.radians(deg)/2; v=np.zeros(4); v[ax]=np.sin(r); v[3]=np.cos(r); return v
def qeuler(rx=0,ry=0,rz=0):  # ordem Y*X*Z
    return qmul(qmul(qaxis(1,ry),qaxis(0,rx)),qaxis(2,rz))
def qmat(q):
    x,y,z,w=q
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])

def fk(local_q, hips_t=None):
    """local_q: dict nome->quat. Retorna lista de matrizes 4x4 mundo."""
    M=[None]*len(NAMES)
    for i,n in enumerate(NAMES):
        m=np.eye(4); m[:3,:3]=qmat(local_q.get(n,np.array([0,0,0,1.0])))
        t=REST_LOCAL[i].copy()
        if i==0 and hips_t is not None: t=t+hips_t
        m[:3,3]=t
        M[i]=m if PARENT[i] is None else M[PARENT[i]]@m
    return M
def rest_inv():
    out=[]
    for i in range(len(NAMES)):
        m=np.eye(4); m[:3,3]=REST_WORLD[i]; out.append(np.linalg.inv(m))
    return out
def skin(P_rest, idx4, w4, local_q, hips_t=None):
    M=fk(local_q,hips_t); inv=rest_inv()
    SK=np.stack([M[i]@inv[i] for i in range(len(NAMES))])  # (J,4,4)
    Ph=np.concatenate([P_rest,np.ones((len(P_rest),1))],1)
    out=np.zeros((len(P_rest),3))
    for k in range(4):
        out+=w4[:,k:k+1]*np.einsum('nij,nj->ni',SK[idx4[:,k]],Ph)[:,:3]
    return out
