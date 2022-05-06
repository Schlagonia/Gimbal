//returns an object in the list with chainId parameter
const getObject = (list, chainId) => {
  
    let obj;
    for (let i = 0; i < list.length; i++) {
        let chain = list[i].chain
        
        if (chain == chainId) {
            obj = list[i]
        }
    }

    return obj;
  }


module.exports = {
    getObject
}