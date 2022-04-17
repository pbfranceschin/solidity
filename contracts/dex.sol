pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./wallet.sol";

contract Dex is Wallet {
    using SafeMath for uint256;

    struct order {
        uint id;
        address trader;
        bool buyOrder; //false if its a sell order
        bytes32 ticker;
        uint amount;
        uint price;
    }

    mapping(bytes32 => mapping(bool => order[])) public orderbook; // true == buy / sell == false

    event debug(uint n);

    function getOrderbook(bytes32 ticker, bool side) view public returns(order[] memory){
        return orderbook[ticker][side];
    }

    uint nextOrderId = 0;

    function limitOrder(bytes32 ticker, bool side, uint256 amount, uint256 price) public {
        if(side == true){
            require(balances[msg.sender]["ETH"] >= amount.mul(price), "Dex: insufficient funds");
        }
        else if(side == false){
            require(balances[msg.sender][ticker] >= amount, "Dex: insufficient balance");
        }

        order[] storage orders = orderbook[ticker][side];
        orders.push(
            order(nextOrderId, msg.sender, side, ticker, amount, price)
        );
        //bubble sort
        if(side == true){ // buy order: high to low
            uint i;
            for(i = orders.length - 1; i > 0; i--){  //orders.length > 0 because we just .pushed
                
                if( orders.length < 2 || orders[i].price < orders[i-1].price ){
                    break;
                }
                order memory aux = orders[i-1];
                orders[i-1] = orders[i];
                orders[i] = aux;
            }
        }
        else if(side == false){//sell order: low to high
            uint i;
            for(i = orders.length - 1; i > 0; i--){
                if( orders.length < 2 || orders[i].price > orders[i-1].price ){
                    break;
                }
                order memory aux = orders[i-1];
                orders[i-1] = orders[i];
                orders[i] = aux;
            }
        }

        nextOrderId++;
        //orderbook[ticker][side] = orders;
    }

    uint x=0;
    
    function marketOrder( bytes32 ticker, bool side, uint256 amount) public returns(uint) {
        emit debug(x);
        //
        order[] storage orders = orderbook[ticker][!side];
        
        uint remaining = amount;
        uint i = 0;
        if(side == true) { // BUY order: amount correspods to the maximum amount the user wants to buy
                            // the total amount bought will depend on the prices asked in the orderbook
            
           while( remaining > 0  || i < orders.length ) { //
                x++;
                emit debug(x);
                if( balances[msg.sender]["ETH"] < orders[i].price ){
                    x++;
                    emit debug(x);
                    //return 2;
                    break;
                    
                }
                else if( remaining.mul( orders[i].price ) <= balances[msg.sender]["ETH"]  ) { 
                // ETH balance covers remainder of tx at current price
                    x++;
                    emit debug(x);
                    //return 2;
                    if ( remaining <= orders[i].amount){ // tx can be completed by 1st order
                        x++;
                        emit debug(x);
                        //execute trade of 
                        uint n = remaining.mul(orders[i].price); //wei
                        // for t = remaining tokens
                        _trade(msg.sender, orders[i].trader, ticker, n, remaining);
                        
                        orders[i].amount -= remaining;    //update orders[i].amount
                        remaining = 0;    //update remaining = 0
                    }
                    else{ // remaining > orders[i].amount
                         //execute trade of t = orders[i].amount tokens
                         // for 
                         uint n = orders[i].amount*orders[i].price;// wei
                        _trade( msg.sender, orders[i].trader, ticker, n, orders[i].amount );
                        
                        remaining -= orders[i].amount;
                        orders[i].amount = 0;
                        // return 2;
                    }
                    
                }    
                else if ( amount.mul( orders[i].price ) >= balances[msg.sender]["ETH"] ){
                // remainder of tx can't be completed at current price
                // how much can be bought? R: t = balance[msg.sender]["ETH"]/ordes[0].price
                    uint t = balances[msg.sender]["ETH"]/orders[0].price;
                    if ( t <= orders[i].amount){
                    // order can cover the amount that can be bought
                    // execute trade of t tokens for n = t*orders[i].price wei
                        uint n = t.mul( orders[i].price );
                        _trade(msg.sender, orders[i].trader, ticker, t, n );
                        
                        // balances[ msg.sender]["ETH"] -= n;
                        // balances[ orders[i].trader ][ ticker ] -= t ;
                        // balances[ msg.sender ][ ticker ] = balances[ msg.sender ][ ticker ].add( t );
                        // balances[ orders[i].trader ]["ETH"] = balances[ orders[i].trader ]["ETH"].add( n );

                        remaining = remaining.sub( t );
                        orders[i].amount -= t ;

                    }
                        
                    else{ // t > orders[i].amount
                    // order cannot cover the amount that can be bought
                    // execute the trade of x = orders[i].amount tokens
                    // for n = x*orders[i].price wei
                        uint x = orders[i].amount ;
                        uint n = x.mul(orders[i].price);
                        _trade( msg.sender, orders[i].trader, ticker, n, x );

                        // balances[ msg.sender]["ETH"] -= n;
                        // balances[ orders[i].trader ][ ticker ] -= x;
                        // balances[ msg.sender ][ ticker ] = balances[ msg.sender ][ ticker ].add( x );
                        // balances[ orders[i].trader ]["ETH"] = balances[ orders[i].trader ]["ETH"].add( n );

                        remaining = remaining.sub( x );
                        orders[i].amount = 0;

                    }
                    
                }

                i++;
            
            }
        } 

        // else{ // SELL order: amount correspond to the exact amount the user wants to sell
        //         // the total amount of ETH received for the sell will depend on the prices 
        //         // offered in the orderbook
        //     require( balances[msg.sender][ticker] >= amount, "Dex: not enough token balance to fill order");
            

        //     while(remaining > 0 || i == orders.length){

        //         if( remaining <= orders[i].amount ){
        //         // 1st order enough to cover remainder of SELL
        //         // trade t = remaining [tokens] for n = t*orders[i].price [wei]
        //             balances[msg.sender][ ticker] -= remaining;
        //             balances[ orders[i].trader ]["ETH"] -= remaining*orders[i].price;
        //             balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add( remaining*orders[i].price );
        //             balances[ orders[i].trader ][ ticker ] = balances[ orders[i].trader ][ ticker ].add(remaining);

        //             remaining = 0;
        //             orders[i].amount -= remaining;
        //         }

        //         else{ //remaining > orders[i].amount
        //         // 1st order not enough to cover SELL
        //         // trade t = orders[i].amount [tokens] for n = t*orders[i].price [wei]
        //             balances[ msg.sender][ ticker ] -= orders[i].amount;
        //             balances[ orders[i].trader ]["ETH"] -= orders[i].amount.mul( orders[i].price );
        //             balances[ msg.sender]["ETH"] = balances[ msg.sender]["ETH"].add( orders[i].amount.mul( orders[i].price ) );
        //             balances[ orders[i].trader ][ ticker ] = balances[ orders[i].trader ][ ticker ].add( orders[i].amount );

        //             remaining -= orders[i].amount;
        //             orders[i].amount = 0;


        //         }
        //         i++;

        //     }

        // } 
        // exclude the orders that got executed
        uint j;
        if(orders[i].amount == 0){
            i++; // i é o índice da nova 1a ordem
        }
        for(j = i; j < orders.length; j++){ // problem: unbouded amount of gas used (size of array unknown)
            orders[j-i] = orders[j];
        }
        for(j=0; j<i ; j++){
            orders.pop();
        }   

        // return outcome of Trade (2 == complete / 1 == partially complete / 0 == not done)    
        if(remaining == 0){
            return 2;
        }
        else if(remaining == amount){
            return 0;
        }
        else{
            return 1;
        }
    }

}