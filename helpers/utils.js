//returns an object in the list with chainId parameter
const getObject = (list, chainId) => {
  
    for (let i = 0; i < list.length; i++) {
        let chain = list[i].chain
        
        if (chain == chainId) {
            return list[i]
        }
    }

  }

const getIndex = (list, chainId) => {
    for (let i = 0; i < list.length; i++) {
        let chain = list[i].chain
        
        if (chain == chainId) {
            return i;
        }
    }
}


module.exports = {
    getObject,
    getIndex
}