// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CommerceV2 {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  struct Shop {
    address identity;
    string title;
    string description;
    uint joined;
    string emailOrPhone;
    uint256 volumeTraded;
    Product[] productsListed;
  }

  struct Product {
    uint256 id;
    bool expired;
    string[] media;
    string description;
    string title;
    uint256 timePosted;
    uint256 likes;
    address[] likea;
    address[] dislikea;
    uint256 dislikes;
    uint256 category;
    uint256 price;
    uint256 amount;
  }

  struct Customer {
    address identity;
    ProductBought[] productsBought;
  }

  struct ProductBought {
    uint256 id;
    string[] media;
    string title;
    string description;
    uint256 timePosted;
    uint256 amount;
  }

  mapping (uint256 => Shop) public shops;
  mapping (address => bool) public isShop;
  mapping (address => bool) public isClient;
  mapping (uint256 => Customer) public clients;
  uint256 public shopAmount;
  uint256 public clientAmount;
  uint256 public productAmount;

  function returnONEShop(address _add) public view returns (Shop memory) {
    Shop memory shopp = shops[getShopId(_add)];
    require(msg.sender==shopp.identity,"need shop owner");
    return shopp;
  }

  function isAddressThere(address _add,address[] memory _s) public pure returns (bool) {
    bool f = false;
    for (uint z =0;z<_s.length;z++){
      if (_s[z]==_add) {
        f=true;
        break;
      }
    }
    return f;
  }

  function likeOneProd(address _add,uint256 _id) public {
    Shop storage shopp = shops[getShopId(_add)];
    require(isClient[msg.sender]==true,"need client");
    require(isAddressThere(msg.sender,shopp.productsListed[_id].likea)==false,"not again");
    require(isAddressThere(msg.sender,shopp.productsListed[_id].dislikea)==false,"only one side");
    shopp.productsListed[_id].likes++;
    shopp.productsListed[_id].likea.push(msg.sender);
  }

  function addMedia(uint256 _id,string[] memory _media) public {
    Shop storage shop=shops[getShopId(msg.sender)];
    require(shop.identity==msg.sender,"need shop owner");
    require(shop.productsListed[_id].expired==false,"no expired");
    if (shop.productsListed[_id].media.length+_media.length<=14) {
      for (uint h=0;h<_media.length;h++){
        shop.productsListed[_id].media.push(_media[h]);
      }
    }
  }

  function changeProdTitleNORDescrip(uint256 _id,string memory _t,string memory _d) public {
    Shop storage shopp = shops[getShopId(msg.sender)];
    require(shopp.identity==msg.sender,"shop owner");
    require(shopp.productsListed[_id].expired==false,"no expired");
    shopp.productsListed[_id].title=_t;
    shopp.productsListed[_id].description=_d;
  }

  function addClient() public returns (uint256) {
    require(isClient[msg.sender]!=true && isShop[msg.sender]!=true && msg.sender!=owner,"new address needed");
    Customer storage buyer = clients[clientAmount];
    buyer.identity = msg.sender;
    isClient[msg.sender]=true;
    clientAmount++;
    return clientAmount -1;
  }
  
  function addShop(
    string memory _name, string memory _email,
    string memory _desp
  ) public returns (uint256) {
    require(isShop[msg.sender]!=true && isClient[msg.sender]==false && msg.sender!=owner,"new address only");
    Shop storage shop = shops[shopAmount];
    shop.title = _name;
    shop.identity = msg.sender;
    shop.emailOrPhone = _email;
    shop.description=_desp;
    shop.volumeTraded=0;
    shop.joined = block.timestamp;
    shopAmount++;
    isShop[msg.sender]=true;
    return shopAmount-1;
  }

  function getShopId(address _add) public view returns (uint256) {
    uint256 id;
    for (uint r =0;r<shopAmount;r++){
      if (shops[r].identity==_add){
        id=r;
        break;
      }
    }
    return id;
  }

  function addProductS(Product[] memory _list) public returns (uint256) {
    Shop storage shop = shops[getShopId(msg.sender)];
    require(msg.sender==shop.identity,"shop owner");
    for (uint e = 0;e<_list.length;e++){
      shop.productsListed.push(_list[e]);
      productAmount++;
    }
    return productAmount-_list.length;
  }

  function getClientId() public view returns (uint256) {
    require(isClient[msg.sender]==true,"need client");
    uint256 id;
    for (uint g = 0;g<clientAmount;g++){
      if (clients[g].identity==msg.sender) {
        id = g;
        break;
      }
    }
    return id;
  }

  function sendFund(address _shop,uint256 _v) public payable {
    address payable shop = payable(_shop);
    address payable ownn = payable(owner);
    shop.transfer(_v*92/100);
    (bool paid,)=ownn.call{value:_v*8/100}("");
    if (paid) {}
  }

  function buySameProduct(address _shop,uint256 _alphaid,uint256 _amo) public payable {
    Shop storage shop = shops[getShopId(_shop)];
    Product memory product = shop.productsListed[_alphaid];
    require(isClient[msg.sender]==true,"need client");
    uint256 c = 0;
    require(product.expired==false,"no expired");
    //require(msg.sender.balance>product.price*_amo,"if total 12 coins; then balance > 13");
    Customer storage client = clients[getClientId()];
    for (uint p = 0;p < _amo; p++) {
      if (product.amount!=0) {
        bool isThere;
        uint256 inOrder;
        (isThere,inOrder)=isProductThere(_alphaid,product.timePosted);
        if (isThere==true) {
          client.productsBought[inOrder].amount+=1;
        } else {
          ProductBought memory bought;
          bought.id = product.id;
          bought.media = product.media;
          bought.description = product.description;
          bought.timePosted = product.timePosted;
          bought.amount = 1;
          bought.title = product.title;
          client.productsBought.push(bought);
        }
        product.amount--;
        productAmount--;
        c++;
      } else {
        product.expired=true;
        break;
      }
    }
    if (c > 0) {
      shop.volumeTraded+=product.price*2*92/100;
      sendFund(_shop,product.price*2);
    }
  }

  function isProductThere(uint256 _alphaid, uint256 _t) public view returns (bool,uint256) {
    require(isClient[msg.sender]==true,"need client");
    Customer memory client = clients[getClientId()];
    bool haha = false;
    uint256 id = 0;
    for (uint g=0;g<client.productsBought.length;g++) {
      if (client.productsBought[g].id == _alphaid && client.productsBought[g].timePosted==_t) {
        haha = true;
        id = g;
        break;
      }
    }
    return (haha,id);
  }

  function discountOneProductInOneShop(uint256 _prod,uint256 _discountPercentInt) public {
    Shop storage shop = shops[getShopId(msg.sender)];
    require(shop.productsListed[_prod].expired==false,"no expired");
    require(_discountPercentInt<=90 && msg.sender == shop.identity,"min 10%");
    uint256 aft = shop.productsListed[_prod].price*_discountPercentInt/100;
    require(aft >= 8,"bare minimum");
    shop.productsListed[_prod].price = aft;
  }

  function changeShopTitleNDESP(string memory _t,string memory _des) public {
    Shop storage shop =shops[getShopId(msg.sender)];
    require(msg.sender==shop.identity,"shop owner");
    shop.title = _t;
    shop.description=_des;
  }

  function expireAProductInOneShop(uint256 _prod) public {
    Shop storage shop = shops[getShopId(msg.sender)];
    require(msg.sender==shop.identity,"only shop owner");
    require(shop.productsListed[_prod].expired==false,"no expired");
    shop.productsListed[_prod].expired = true;
  }

  function clientReturnShopAvailableProduct(address _add) public view returns (Shop memory) {
    Shop memory shop = shops[getShopId(_add)];
    Product[] memory product = returnShopProducts(_add);
    shop.productsListed = product;
    return shop;
  }

  function returnShopProducts(address _add) public view returns (Product[] memory) {
    uint256 id = getShopId(_add);
    Product[] memory productsS = new Product[](shops[id].productsListed.length);
    Product[] memory productt = shops[id].productsListed;
    uint c = 0;
    for (uint h=0;h<productt.length;h++) {
      if (productt[h].expired==false && productt[h].amount > 0) {
        productsS[c]=productt[h];
        c++;
      }
    }
    if (c==shops[id].productsListed.length) {
      return productsS;
    } else {
      Product[] memory productOut = new Product[](c);
      for (uint y=0;y<c;y++) {
        productOut[y]=productsS[y];
      }
      return productOut;
    }
  }

  function shopSearchByOneCategory(address _add,uint256 _s) public view returns (Product[] memory) {
    Product[] memory unfiltered = returnShopProducts(_add);
    Product[] memory filteredShopProduct = new Product[](unfiltered.length);
    require(_s<17 && _s>0,"16 categories only");
    uint c = 0;
    for (uint x =0;x<unfiltered.length;x++){
      if (unfiltered[x].category==_s) {
        filteredShopProduct[c]=unfiltered[x];
        c++;
      }
    }
    if (c==unfiltered.length) {
      return filteredShopProduct;
    } else {
      Product[] memory out = new Product[](c);
      for (uint n = 0;n<c;n++) {
        out[n]=filteredShopProduct[n];
      }
      return out;
    }
  }

  function mainSearchByOneCategory(uint256 _s) public view returns (Product[] memory) {
    Product[] memory filteredProducts = new Product[](productAmount);
    uint c = 0;
    require(_s>0 && _s<17,"16 categories only");
    for (uint d=0;d<shopAmount;d++) {
      Product[] memory shopProduct = returnShopProducts(shops[d].identity);
      for (uint w=0;w<shopProduct.length;w++){
        if (shopProduct[w].category==_s) {
          filteredProducts[c]=shopProduct[w];
          c++;
        }
      }
    }
    if (c==productAmount){
      return filteredProducts;
    } else {
      Product[] memory out = new Product[](c);
      for (uint h = 0;h<c;h++) {
        out[h]=filteredProducts[h];
      }
      return out;
    }
  }

  function returnBought() public view returns (ProductBought[] memory) {
    Customer memory client = clients[getClientId()];
    require(msg.sender==client.identity,"need client");
    return client.productsBought;
  }

  function returnTopN() public view returns (Product[] memory) {
    if (productAmount<1000){
      Product[] memory top100 = new Product[](productAmount);
      uint c = 0;
      for (uint h=0;h<shopAmount;h++) {
        Product[] memory shopProds = returnShopProducts(shops[h].identity);
        for (uint d = 0;d<shopProds.length;d++) {
          top100[c]=shopProds[d];
          c++;
        }
      }
      if (c==productAmount) {
        return top100;
      } else {
        Product[] memory top = new Product[](c);
        for (uint j = 0; j < c; j++) {
          top[j]=top100[j];
        }
        return top;
      }
    } else {
      Product[] memory top100 = new Product[](1000);
      uint c = 0;
      for (uint h=0;h<shopAmount;h++) {
        Product[] memory shopProds = returnShopProducts(shops[h].identity);
        for (uint d = 0;d<shopProds.length;d++) {
          if (top100.length!=1000) {
            top100[c]=shopProds[d];
            c++;
          } else {
            uint256 index = 0;
            for (uint g = 1; g < top100.length; g++){
              if (top100[g].likes<top100[index].likes) {
                index = g;
              }
            }
            if (shopProds[d].likes>top100[index].likes) {
              top100[index]=shopProds[d];
            }
          }
        }
      }
      if (c==1000) {
        return top100;
      } else {
        Product[] memory top = new Product[](c);
        for (uint j = 0; j < c; j++) {
          top[j]=top100[j];
        }
        return top;
      }
    }
  }

  function reportOneProduct(address _shop,uint256 _id) public {
    require(isClient[msg.sender]==true,"only clients");
    Shop storage shopp = shops[getShopId(_shop)];
    require(shopp.productsListed[_id].expired==false,"no expired");
    if (shopp.productsListed[_id].dislikes!=400) {
      require(isAddressThere(msg.sender,shopp.productsListed[_id].likea)==false,"one side");
      require(isAddressThere(msg.sender,shopp.productsListed[_id].dislikea)==false,"not again");
      shopp.productsListed[_id].dislikes++;
      shopp.productsListed[_id].dislikea.push(msg.sender);
    } else {
      shopp.productsListed[_id].expired=true;
    }
  }
}
