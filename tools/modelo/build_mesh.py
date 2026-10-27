import numpy as np
from PIL import Image
import riglib as R
pos=np.load('pos.npy').astype(np.float64); uv=np.load('uv.npy').astype(np.float64)
idx=np.load('idx.npy').reshape(-1,3).astype(np.int64); lab=np.load('island.npy')
# grupo do osso dominante (impede soldar braço no tronco)
tex=np.asarray(Image.open('tex0.jpg').convert('RGB').resize((1024,1024))).astype(int)
def colors(uvs): return tex[(uvs[:,1]*1023).astype(int),(uvs[:,0]*1023).astype(int)]
def masks(P,uvs):
    c=colors(uvs); r,g,bl=c[:,0],c[:,1],c[:,2]
    brown=(r>g)&(g>bl)&(r-bl>30)&(r<175)&(P[:,1]>-0.22)&(P[:,1]<0.12)&(np.abs(P[:,0])<0.31)
    orange=(r>190)&(g>90)&(g<185)&(bl<90)&(P[:,1]>0.18)&(P[:,1]<0.64)&(np.abs(P[:,0])>0.1)
    return [('hips',brown),('chest',orange)]
i4o,w4o=R.weights(pos,masks(pos,uv))
prim=np.array(R.NAMES)[i4o[np.arange(len(pos)),np.argmax(w4o,1)]]
grp=np.zeros(len(pos),int)
for k,nm in enumerate(['upperarm_L','forearm_L','hand_L']): grp[prim==nm]=1
for nm in ['upperarm_R','forearm_R','hand_R']: grp[prim==nm]=2
for nm in ['thigh_L','shin_L','foot_L']: grp[prim==nm]=3
for nm in ['thigh_R','shin_R','foot_R']: grp[prim==nm]=4
head=(pos[:,1]>0.62)
cellv=np.where(head,0.011,0.02)
c=np.floor((pos-pos.min(0))/cellv[:,None]).astype(np.int64)
ckey=(((c[:,0]*2048+c[:,1])*2048+c[:,2])*8+grp)*2+head.astype(np.int64)
cu,cinv=np.unique(ckey,return_inverse=True); cinv=cinv.ravel()
cnt=np.bincount(cinv)
cpos=np.stack([np.bincount(cinv,pos[:,k]) for k in range(3)],1)/cnt[:,None]
vk=np.stack([cinv,lab],1)
vu,vinv=np.unique(vk,axis=0,return_inverse=True); vinv=vinv.ravel()
vcnt=np.bincount(vinv)
nuv=np.stack([np.bincount(vinv,uv[:,k]) for k in range(2)],1)/vcnt[:,None]
vcell=vu[:,0]
npos=cpos[vcell]
tri=vinv[idx]
ok=(tri[:,0]!=tri[:,1])&(tri[:,1]!=tri[:,2])&(tri[:,0]!=tri[:,2])
tri=tri[ok]
# remove triângulos duplicados
s=np.sort(tri,1); _,first=np.unique(s,axis=0,return_index=True); tri=tri[np.sort(first)]
i4pre,w4pre=R.weights(npos,masks(npos,nuv))
# normais por célula
fn=np.cross(npos[tri[:,1]]-npos[tri[:,0]],npos[tri[:,2]]-npos[tri[:,0]])
cn=np.zeros((len(cu),3))
for k in range(3): np.add.at(cn,vcell[tri[:,k]],fn)
cn/=np.maximum(np.linalg.norm(cn,axis=1,keepdims=True),1e-9)
nn=cn[vcell]
# remove triângulos que ligam ossos não adjacentes (mãos fundidas ao corpo no modelo original)
pb=i4pre[np.arange(len(npos)),np.argmax(w4pre,1)]
par=R.PARENT
def adj(a,b): return a==b or par[a]==b or par[b]==a or (par[a] is not None and par[a]==par[b] and R.NAMES[par[a]] in ('hips',))
okt=np.ones(len(tri),bool)
for (p,q) in ((0,1),(1,2),(0,2)):
    A=pb[tri[:,p]]; B=pb[tri[:,q]]
    okt&=np.array([adj(int(a),int(b)) for a,b in zip(A,B)])
print('removidos por conexão não adjacente:',(~okt).sum())
tri=tri[okt]
# remove vértices não usados
used=np.unique(tri); remap=-np.ones(len(npos),int); remap[used]=np.arange(len(used))
npos,nuv,nn=npos[used],nuv[used],nn[used]; tri=remap[tri]
print('verts',len(npos),'tris',len(tri))
i4,w4=R.weights(npos,masks(npos,nuv))
np.savez('lowpoly.npz',pos=npos,uv=nuv,nrm=nn,tri=tri,j=i4,w=w4)
