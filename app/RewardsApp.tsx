"use client";
import { useCallback, useEffect, useState } from "react";
import { BrowserProvider, Contract, formatUnits, isAddress } from "ethers";
import { MiniKit, getWorldAppProvider } from "@worldcoin/minikit-js";

declare global { interface Window { ethereum?: { request: (args:{method:string;params?:unknown[]})=>Promise<unknown> } } }
const CHAIN_ID = Number(process.env.NEXT_PUBLIC_CHAIN_ID || 480);
const REWARDS = process.env.NEXT_PUBLIC_REWARDS_CONTRACT || "";
const TOKEN = process.env.NEXT_PUBLIC_ADV_TOKEN || "0x6d13932b942de3ee93d0e519be41b9ef46cf7fda";
const ABI = ["function claim()", "function rewardAmount() view returns (uint256)", "function nextClaimAt(address) view returns (uint256)", "function token() view returns (address)", "function paused() view returns (bool)"];
const ERC20 = ["function balanceOf(address) view returns (uint256)", "function decimals() view returns (uint8)", "function symbol() view returns (string)"];
const configured = isAddress(REWARDS) && REWARDS !== "0x0000000000000000000000000000000000000000";
const short = (a:string) => a.slice(0,6)+"…"+a.slice(-4);
const timer = (s:number) => [Math.floor(s/3600),Math.floor(s%3600/60),s%60].map(n=>String(n).padStart(2,"0")).join(":");

export default function RewardsApp() {
 const [account,setAccount]=useState(""); const [balance,setBalance]=useState("—"); const [symbol,setSymbol]=useState("ADV");
 const [reward,setReward]=useState("25"); const [next,setNext]=useState(0); const [now,setNow]=useState(0);
 const [paused,setPaused]=useState(false); const [busy,setBusy]=useState(false); const [message,setMessage]=useState("Conecta tu wallet para consultar el saldo.");
 const [error,setError]=useState(""); const [tx,setTx]=useState("");
 const provider=useCallback(async()=>{
  const injected=MiniKit.isInstalled()?getWorldAppProvider():window.ethereum;
  if(!injected) throw new Error("Abre esta app en World App o en un navegador con wallet EVM compatible.");
  return new BrowserProvider(injected as never);
 },[]);
 const refresh=useCallback(async(addr=account)=>{
  if(!addr)return; const p=await provider(); const net=await p.getNetwork();
  if(Number(net.chainId)!==CHAIN_ID)throw new Error("Cambia a World Chain Mainnet (chain ID 480).");
  const tokenAddress=configured?await new Contract(REWARDS,ABI,p).token():TOKEN;
  const token=new Contract(tokenAddress,ERC20,p);
  const [raw,dec,sym]=await Promise.all([token.balanceOf(addr),token.decimals(),token.symbol().catch(()=>"ADV")]);
  setBalance(Number(formatUnits(raw,dec)).toLocaleString("es-CL",{maximumFractionDigits:4})); setSymbol(String(sym));
  if(configured){const c=new Contract(REWARDS,ABI,p);const [amount,n,pause]=await Promise.all([c.rewardAmount(),c.nextClaimAt(addr),c.paused()]);setReward(Number(formatUnits(amount,dec)).toLocaleString("es-CL",{maximumFractionDigits:4}));setNext(Number(n));setPaused(Boolean(pause));}
 },[account,provider]);
 useEffect(()=>{setNow(Math.floor(Date.now()/1000));const i=window.setInterval(()=>setNow(Math.floor(Date.now()/1000)),1000);return()=>window.clearInterval(i)},[]);
 const connect=async()=>{setError("");setBusy(true);try{const p=await provider();const a=await p.send("eth_requestAccounts",[]) as string[];if(!a[0])throw new Error("No se seleccionó wallet.");setAccount(a[0]);await refresh(a[0]);setMessage(configured?"Wallet conectada. Estado leído desde World Chain.":"Wallet conectada. Falta desplegar y configurar el contrato de recompensas.");}catch(e){setError(e instanceof Error?e.message:"No se pudo conectar la wallet.");}finally{setBusy(false)}};
 const claim=async()=>{setError("");setTx("");setBusy(true);try{if(!configured)throw new Error("Reclamaciones desactivadas: falta configurar la dirección del contrato desplegado.");if(!account)throw new Error("Conecta primero tu wallet.");const p=await provider();const net=await p.getNetwork();if(Number(net.chainId)!==CHAIN_ID)throw new Error("Cambia a World Chain Mainnet (480).");const c=new Contract(REWARDS,ABI,await p.getSigner());const sent=await c.claim();setTx(sent.hash);setMessage("Transacción enviada. Esperando confirmación…");await sent.wait();setMessage("¡Recompensa confirmada en blockchain!");await refresh(account);}catch(e){setError(e instanceof Error?e.message:"La reclamación falló o fue cancelada.");}finally{setBusy(false)}};
 const remaining=Math.max(0,next-now);const canClaim=!!account&&configured&&!paused&&remaining===0&&!busy;
 return <main className="shell">
  <header className="topbar"><div className="brand"><div className="coin">A</div><div><strong>ADV Rewards</strong><span>RECOMPENSAS DIARIAS · WORLD CHAIN</span></div></div><div className="network"><i/> {MiniKit.isInstalled()?"World App":"World Chain"}</div></header>
  <section className="hero"><div className="eyebrow">✦ TU RUTINA, TUS RECOMPENSAS</div><h1>Vuelve cada día.<br/><em>Gana ADV.</em></h1><p className="intro">Una recompensa diaria, directamente en tu wallet. Transparente y verificable en blockchain.</p>
   <div className="balance-card"><div className="card-top"><span>Tu saldo</span><span className="live"><i/> {account?"WALLET CONECTADA":"WALLET NO CONECTADA"}</span></div><div className="balance">{balance} <small>{symbol}</small></div><div className="wallet-row"><span>{account?short(account):"Conecta tu wallet compatible"}</span>{account&&<button className="text-button" onClick={()=>refresh().catch(e=>setError(e.message))}>Actualizar ↻</button>}</div></div>
   <div className="claim-card"><div className="claim-heading"><div><span className="mini-label">RECOMPENSA DIARIA</span><h2>Tu próximo premio</h2></div><div className="calendar">✦</div></div>
    <div className="reward-line"><div className="reward-number">+{reward} <span>{symbol}</span></div><span className={"status-pill "+(canClaim?"available":"")}>{paused?"Pausado":!configured?"Pendiente de activar":!account?"Conecta wallet":remaining>0?"Vuelve pronto":"Disponible"}</span></div>
    {account&&configured&&remaining>0&&<div className="countdown"><span>Próxima recompensa en</span><strong>{timer(remaining)}</strong></div>}
    {!account?<button className="claim-button" disabled={busy} onClick={connect}>{busy?"Conectando wallet…":"Conectar wallet"}</button>:<button className="claim-button" disabled={!canClaim} onClick={claim}>{busy?"Confirmando transacción…":!configured?"Contrato pendiente de configurar":paused?"Recompensas pausadas":remaining>0?"Recompensa ya reclamada":"✦ Reclamar recompensa"}</button>}
    {!configured&&<p className="hint">No se envían tokens hasta desplegar, financiar y configurar el contrato ADV Rewards.</p>}
    {message&&<p className="hint">{message}</p>}{error&&<p className="error" role="alert">{error}</p>}{tx&&<p className="success">Transacción: <a href={"https://worldscan.org/tx/"+tx} target="_blank" rel="noreferrer">Ver en Worldscan ↗</a></p>}
   </div>
   <div className="feature-row"><div><b>◷</b><strong>Una vez al día</strong><small>Intervalo controlado por contrato</small></div><div><b>⌁</b><strong>On-chain</strong><small>Transacciones verificables</small></div><div><b>◇</b><strong>Tu wallet</strong><small>Tú controlas tus activos</small></div></div>
  </section><footer><span>ADV REWARDS</span><span>WORLD CHAIN · {CHAIN_ID}</span><a href="https://docs.world.org/mini-apps" target="_blank" rel="noreferrer">World Mini Apps ↗</a></footer>
 </main>;
}
