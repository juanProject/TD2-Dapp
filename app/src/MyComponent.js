import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import { Card } from "../src/ships/Card/Card.controller";

const { AccountData, ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => {
  // destructure drizzle and drizzleState from props
  return (
    <div className="App">
      <div className="section">
        <h2>Active Account</h2>
        <AccountData drizzle={drizzle} drizzleState={drizzleState} accountIndex={0} units="ether" precision={3} />
      </div>

      <div className="section">
        <h2>Urental Interface</h2>
        <p>
          <b>Balance : </b> <ContractData drizzle={drizzle} drizzleState={drizzleState} contract="Urental" method="getContractBalance" />
        </p>
          <p>
            <b>Create Rent</b>
          </p>
          <ContractForm drizzle={drizzle} drizzleState={drizzleState} contract="Urental" method="rent" sendArgs={{ gas: 3000000, value: 1500000000000000000 }} />

          <p>
            <b>Launch Rent</b>
          </p>
          <ContractForm drizzle={drizzle} drizzleState={drizzleState} contract="Urental" method="launchRent" sendArgs={{ from: drizzleState.accounts[2] }}/>

          <p>
            <b>Release Rent Seller</b>
          </p>
          <ContractForm drizzle={drizzle} drizzleState={drizzleState} contract="Urental" method="releaseRent" sendArgs={{ from: drizzleState.accounts[1] }}/>

          <p>
            <b>Release Rent Buyer</b>
          </p>
          <ContractForm drizzle={drizzle} drizzleState={drizzleState} contract="Urental" method="releaseRent" sendArgs={{ from: drizzleState.accounts[2] }}/>

          <p>Ask Caution</p>
          <ContractForm drizzle={drizzle} drizzleState={drizzleState} contract="Urental" method="askCaution" methodArgs={{ from: drizzleState.accounts[1] }} />

          <p>
            <b>Get Rent</b>
          </p>
          <ContractData
            drizzle={drizzle} 
            drizzleState={drizzleState} 
            contract="Urental"
            method="getRent" 
            methodArgs={[[0x01]]}
            render={(e) => {
              console.log(e);
              const buyer = e[0];
              const seller = e[1];
              const price = e[2];
              const caution = e[3];
              const duration = e[4];
              const state = e[5];
            return <ul>
                <li>{buyer}</li>
                <li>{seller}</li>
                <li>{price}</li>
                <li>{caution}</li>
                <li>{duration}</li>
                <li>{state}</li>
              </ul>;
            }}  />
          </div>
    </div>
  );
};
